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
