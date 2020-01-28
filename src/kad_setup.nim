import options, tables
import libp2p/[switch, peer, peerinfo, connection, multiaddress, crypto/crypto]
import libp2p/transports/[transport, tcptransport]
import libp2p/muxers/[muxer, mplex/mplex, mplex/types]
import libp2p/protocols/[identify, secure/secure, secure/secio]

export
  switch, peer, peerinfo, connection, multiaddress, crypto

# Like newStandardSwitch in libp2p/standard_setup tests but without any pubsub
# XXX: What does pubSub option imply for Switch?
proc newKadSwitch*(privKey = none(PrivateKey),
                   address = MultiAddress.init("/ip4/127.0.0.1/tcp/0"),
                   triggerSelf = false): Switch =
  proc createMplex(conn: Connection): Muxer =
    result = newMplex(conn)
    
  let
    seckey = privKey.get(otherwise = PrivateKey.random(ECDSA))
    peerInfo = PeerInfo.init(seckey, @[address])
    mplexProvider = newMuxerProvider(createMplex, MplexCodec)
    transports = @[Transport(newTransport(TcpTransport))]
    muxers = {MplexCodec: mplexProvider}.toTable
    identify = newIdentify(peerInfo)
    secureManagers = {SecioCodec: Secure(newSecio seckey)}.toTable

  result = newSwitch(peerInfo,
                     transports,
                     identify,
                     muxers,
                     secureManagers = secureManagers)
