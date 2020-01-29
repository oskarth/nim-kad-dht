import tables
import chronos
import libp2p/[switch,
               multistream,
               protocols/identify,
               connection,
               transports/transport,
               transports/tcptransport,
               multiaddress,
               peerinfo,
               crypto/crypto,
               peer,
               protocols/protocol,
               muxers/muxer,
               muxers/mplex/mplex,
               muxers/mplex/types,
               protocols/secure/secio,
               protocols/secure/secure]

const KadCodec = "/test/kademlia/1.0.0" # custom protocol string

const k = 2 # maximum number of peers in bucket, test setting, should be 20
const b = 160 # size of bits of keys used to identify nodes and data

# Should parameterize by b, size of bits of keys (Peer ID dependent?)
type
  KadPeer = ref object of RootObj
    peerInfo: PeerInfo
  KBucket = array[k, KadPeer] # should be k length
  KadProto* = ref object of LPProtocol # declare a custom protocol
    peerInfo: PeerInfo # this peer's info, should be b length
    Kbuckets: array[b, KBucket] # should be b length

# Returns XOR distance as PeerID
# Assuming these are of equal length, b
# Which result type do we want here?
proc xor_distance(a, b: PeerID): PeerID =
  var data: seq[byte]
  for i in 0..<a.data.len:
    data.add(a.data[i] xor b.data[i])
  return PeerID(data: data)

method init(p: KadProto) {.gcsafe.} =
  # handle incoming connections in closure
  proc handle(conn: Connection, proto: string) {.async, gcsafe.} =
    echo "Got from remote - ", cast[string](await conn.readLp())
    await conn.writeLp("Hello!")
    await conn.close()

  p.codec = KadCodec # init proto with the correct string id
  p.handler = handle # set proto handler

# TODO: Setup kbuckets, fix byte to bit to know which contact
method addContact(p: KadProto, contact: PeerInfo) {.gcsafe.} =
  echo ("addContact ", contact)
  # Find which_kbucket(self, c.id)
  #p.kbuckets[0].add(c)

proc createSwitch(ma: MultiAddress): (Switch, PeerInfo) =
  ## Helper to create a swith

  let seckey = PrivateKey.random(RSA) # use a random key for peer id
  var peerInfo = PeerInfo.init(seckey) # create a peer id and assign
  peerInfo.addrs.add(ma) # set this peer's multiaddresses (can be any number)

  let identify = newIdentify(peerInfo) # create the identify proto

  proc createMplex(conn: Connection): Muxer =
    # helper proc to create multiplexers,
    # use this to perform any custom setup up,
    # such as adjusting timeout or anything else
    # that the muxer requires
    result = newMplex(conn)

  let mplexProvider = newMuxerProvider(createMplex, MplexCodec) # create multiplexer
  let transports = @[Transport(newTransport(TcpTransport))] # add all transports (tcp only for now, but can be anything in the future)
  let muxers = {MplexCodec: mplexProvider}.toTable() # add all muxers
  let secureManagers = {SecioCodec: Secure(newSecio(seckey))}.toTable() # setup the secio and any other secure provider

  # create the switch
  let switch = newSwitch(peerInfo,
                         transports,
                         identify,
                         muxers,
                         secureManagers)
  result = (switch, peerInfo)

proc main() {.async, gcsafe.} =
  let ma1: MultiAddress = Multiaddress.init("/ip4/0.0.0.0/tcp/0")
  let ma2: MultiAddress = Multiaddress.init("/ip4/0.0.0.0/tcp/0")

  var peerInfo1, peerInfo2: PeerInfo
  var switch1, switch2: Switch
  (switch1, peerInfo1) = createSwitch(ma1) # create node 1

  # setup the custom proto
  let kadProto = new KadProto
  kadProto.init() # run it's init method to perform any required initialization
  switch1.mount(kadProto) # mount the proto
  var switch1Fut = await switch1.start() # start the node

  (switch2, peerInfo2) = createSwitch(ma2) # create node 2
  var switch2Fut = await switch2.start() # start second node
  let conn = await switch2.dial(switch1.peerInfo, KadCodec) # dial the first node

  # XOR distance between two peers
  echo("*** xor_distance ", xor_distance(peerInfo1.peerId, peerInfo2.peerId))

  await conn.writeLp("Hello!") # writeLp send a length prefixed buffer over the wire
  # readLp reads length prefixed bytes and returns a buffer without the prefix
  echo "Remote responded with - ", cast[string](await conn.readLp())

  await allFutures(switch1.stop(), switch2.stop()) # close connections and shutdown all transports
  await allFutures(switch1Fut & switch2Fut) # wait for all transports to shutdown

waitFor(main())
