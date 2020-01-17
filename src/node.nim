import os

import service_pb
import service_twirp

# What does a node do? It implements the following RPC calls:
# ping, store, find_node, find_data

# http://xlattice.sourceforge.net/components/protocol/kademlia/specs.html
# > This RPC involves one node sending a PING message to another, which presumably replies with a PONG. 
# > This has a two-fold effect: the recipient of the PING must update the bucket corresponding to the sender; and, if there is a reply, the sender must update the bucket appropriate to the recipient.
# > All RPC packets are required to carry an RPC identifier assigned by the sender and echoed in the reply. This is a quasi-random number of length B (160 bits).

# Use protobufs for RPC, a la remote log

echo "hi"

var pingRequest = dht_PingRequest()

try:
  pingRequest.id = 1
except:
  echo("invalid id")
  quit(QuitFailure)

echo pingRequest.id

# Send Ping request
