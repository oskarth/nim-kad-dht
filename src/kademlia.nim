import random

# Actual Kademlia network

const
  alpha = 3 # degree of parallelism in network calls
  b = 3 # for testing
  #b = 160   # size of bits of keys used to identify nodes and data
  k = 20    # maximum number of contacts stored in a bucket

# TODO: tExpire, tRefresh, tReplicate, tRepublish constants

type
  NodeID* = array[b, int]

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

proc distance(a: NodeID, b: NodeID): NodeID = 
  for i in 0..<result.len:
    result[i] = a[i] xor b[i]

var anode = genNodeID()
var bnode = genNodeID()
printNodeID(anode)
printNodeID(bnode)
printNodeID(distance(anode,bnode))

#echo("xor", (0b0011 xor 0b0101))
#echo("bit array?", 0b010, " : ", type(0b010))
