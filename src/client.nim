import os
import strformat
import strutils

import service_pb
import service_twirp

# What does a node do? It implements the following RPC calls:
# ping, store, find_node, find_data

# http://xlattice.sourceforge.net/components/protocol/kademlia/specs.html
# > This RPC involves one node sending a PING message to another, which presumably replies with a PONG. 
# > This has a two-fold effect: the recipient of the PING must update the bucket corresponding to the sender; and, if there is a reply, the sender must update the bucket appropriate to the recipient.
# > All RPC packets are required to carry an RPC identifier assigned by the sender and echoed in the reply. This is a quasi-random number of length B (160 bits).

# Use protobufs for RPC, a la remote log

echo "Starting client"

var pingRequest = dht_PingRequest()

try:
  pingRequest.id = 1
except:
  echo("invalid id")
  quit(QuitFailure)

echo("Making a ping request with id ", pingRequest.id)

let client = newDHTServiceClient("http://localhost:8000")

try:
  let pingResp = Ping(client, pingRequest)
  echo(&"I got a pong: {pingResp.id}")
except Exception as e:
  echo(&"error: {e.msg}")


# HERE ATM
# TODO: FindNode request to server
# TODO: make src/node.nim that has a client and server, and allows client part to send in background while getting requests - i.e. alice and bob sleep 5s, then both ping each other every 2 seconds
# TODO: Then, start to hook up to kademlia
