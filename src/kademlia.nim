import random

# Actual Kademlia network

const
  alpha = 3 # degree of parallelism in network calls
  b = 160   # size of bits of keys used to identify nodes and data
  k = 20    # maximum number of contacts stored in a bucket

# TODO: tExpire, tRefresh, tReplicate, tRepublish constants

type
  Bit = range[0..1]
  NodeID* = array[b, Bit]

proc genNodeID(): NodeID =
  for i in 0..<result.len:
    result[i] = rand(1)

# TODO: Persist node id, OR do it based on e.g. hex seed
#
# TODO: Turn BitArray into hex 
proc printNodeID(nodeID: NodeID) =
  var s = ""
  for i in 0..<nodeID.len:
    s = s & $nodeID[i]
  echo("node id: ", s)

var nodeID = genNodeID()
printNodeID(nodeID)

# TODO Distance function
