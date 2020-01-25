# nim-kad-dht

I want to write a Kademlia DHT in Nim.

- Get better intuition for Kademlia by writing an implementation
- Get better at P2P coding in practice by solving a well-known problem
- Get better at Nim

As well as:
- Hopefully useful for Vac/protocol efforts
- Hopefully useful for libp2p efforts

It also ties into ideas such as:
- Discovery v5
- Resource restricted devices
- Efficient routing (classical vs forwarding)
- Service oriented p2p architecture
- Accounting for resources

## TODO

- x Protobuf RPC scaffold
- x Hello ping RPC
- x NodeID
- x Distance fn
- x Kbuckets
- x Contact with address empty
- x Mock Findnode
- x Node lookup logic
- x Join network logic

- Contact with actual address (e.g. localhost port n)
- Kbucket max size and LRU
- Mock RPCs for store/findnode/findvalue (partial)
- Hookup Kademlia to client/server
- Make NodeID random based on seed

## Setup

```
nimble intall https://github.com/oswjk/nimtwirp
```

## Running

```
# RPC test
make
./bin/server
./bin/client

# For Kademlia logic only
nim c -r src/kademlia.nim
```

## Example run (local)

Shows Alice joining network of a few nodes.

```
# > ./kademlia 
Printing network

Alice (bs:0000)
Kademlia connectivity: false
----------------------------------------------------------------
bucket 0: @[]
bucket 1: @[]
bucket 2: @[bs:0110]
bucket 3: @[]


Bob (bs:0110)
Kademlia connectivity: true
----------------------------------------------------------------
bucket 0: @[bs:0111]
bucket 1: @[bs:0101]
bucket 2: @[bs:0011]
bucket 3: @[bs:1000]


Charlie (bs:0011)
Kademlia connectivity: true
----------------------------------------------------------------
bucket 0: @[bs:0010]
bucket 1: @[bs:0001]
bucket 2: @[bs:0110]
bucket 3: @[bs:1000, bs:1100]


Dan (bs:0101)
Kademlia connectivity: false
----------------------------------------------------------------
bucket 0: @[]
bucket 1: @[bs:0110]
bucket 2: @[]
bucket 3: @[bs:1001, bs:1110]

[Alice] iterativeFindNode bs:0000 bs:0000 distance bs:0000
[Alice] Found initial candidate: bs:0110
[Alice] Active contacts: 0 desired: 2
[Alice] Mock dialing bs:0110
[Bob] mockFindNode: looking for up to k=2 contacts closest to: bs:0000
[Bob] Found up to k contacts: @[bs:0011, bs:0101]
[Alice] Response @[bs:0011, bs:0101]
[Alice] Adding new nodes as contacts

Alice (bs:0000)
Kademlia connectivity: false
----------------------------------------------------------------
bucket 0: @[]
bucket 1: @[bs:0011]
bucket 2: @[bs:0110, bs:0101]
bucket 3: @[]

[Alice] Update shortlist @[bs:0011, bs:0101]
[Alice] Found new closestNode bs:0011
[Alice] Active contacts: 1 desired: 2
[Alice] Mock dialing bs:0011
[Charlie] mockFindNode: looking for up to k=2 contacts closest to: bs:0000
[Charlie] Found up to k contacts: @[bs:0001, bs:0010]
[Alice] Response @[bs:0001, bs:0010]
[Alice] Adding new nodes as contacts

Alice (bs:0000)
Kademlia connectivity: false
----------------------------------------------------------------
bucket 0: @[bs:0001]
bucket 1: @[bs:0011, bs:0010]
bucket 2: @[bs:0110, bs:0101]
bucket 3: @[]

[Alice] Update shortlist @[bs:0001, bs:0010]
[Alice] Found new closestNode bs:0001
[Alice] Active contacts: 2 desired: 2
[Alice] Found desired number of active and probed contacts 2 breaking
[Alice] Refreshing most distant bucket
[Alice] Last bucket we want to refresh with random member @[bs:0110, bs:0101]
[Alice] Refreshing bucket 2
Randomize moar
[Alice] Mock dialing random contact from bucket bs:0101
[Dan] mockFindNode: looking for up to k=2 contacts closest to: bs:0101
[Dan] Found up to k contacts: @[bs:0110, bs:1110]
[Alice] Response @[bs:0110, bs:1110]

Alice (bs:0000)
Kademlia connectivity: true
----------------------------------------------------------------
bucket 0: @[bs:0001]
bucket 1: @[bs:0011, bs:0010]
bucket 2: @[bs:0110, bs:0101, bs:0110]
bucket 3: @[bs:1110]
```
