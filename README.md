# nim-kad-dht

I want to write a Kademlia DHT in Nim.

- Get better intuition for Kademlia by writing an implementation
- Get better at P2P coding in practice by solving a well-known problem
- Get better at Nim

As well as:
- Hopefully useful for Vac/protocol efforts
- Hopefully useful for libp2p efforts

## TODO

- x Protobuf RPC scaffold
- x Hello ping RPC
- x NodeID
- x Distance fn
- x Kbuckets
- x Contact with address empty

- Contact with actual address (e.g. localhost port n)
- Kbucket max size and LRU
- Mock RPCs for store/findnode/findvalue
- Node lookup logic
- Hookup Kademlia to client/server
- Join network logic
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
