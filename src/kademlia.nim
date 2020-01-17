import random
import math

# Actual Kademlia network 
const
  alpha = 3 # degree of parallelism in network calls
  b = 3 # for testing
  #b = 160   # size of bits of keys used to identify nodes and data
  k = 20    # maximum number of contacts stored in a bucket

# TODO: tExpire, tRefresh, tReplicate, tRepublish constants

type
  NodeID* = array[b, int]
  KBucket = array[k, NodeID]
  KBuckets = array[b, KBucket]

# XXX: How does rand work? why do I get same number here?
proc genNodeID(): NodeID =
  for i in 0..<result.len:
    result[i] = rand(1)

# TODO: A KBucket should contain Contacts, which in addition to NodeID also including network address

# TODO: Persist node id, OR do it based on e.g. hex seed
#
# TODO: Turn BitArray into hex 
proc printNodeID(nodeID: NodeID) =
  var s = ""
  for i in 0..<nodeID.len:
    s = s & $nodeID[i]
  echo("node id: ", s)

#var nodeID = genNodeID()
#printNodeID(nodeID)

proc distance(a: NodeID, b: NodeID): NodeID = 
  for i in 0..<result.len:
    result[i] = a[i] xor b[i]

# XXX: This is most definitely not the right way to do it, overflows and whatnot
# Don't understand why math.pow only takes floats
func pow2(n: int): int =
  var res = 2
  if n == 0:
    return 1

  for i in 1..<n:
    res = res*2

  return res

# TODO: Generalize type, used to determine which bucket to use
# Assuming bigendian, this is hacky af
proc bitsToDecimal(x: NodeID): int =
  var n = pow2(b-1)
  var res = 0
  for i in 0..<x.len:
    var exp = b-i-1
    n = pow2(exp)
    if x[i] == 1:
      res += n
  return res

var anode = genNodeID()
printNodeID(anode)
echo("anode decimal: ", bitsToDecimal(anode))

var bnode = genNodeID()
printNodeID(bnode)
#printNodeID(distance(anode,bnode))
#echo("distance: ", distance(anode,bnode))

    
#echo("xor", (0b0011 xor 0b0101))
#echo("bit array?", 0b010, " : ", type(0b010))

# TODO: k-bucket
# Which bucket is a contact in? Depends on distance.
# TODO: Print all buckets

proc which_kbucket(self: NodeID, contact: NodeID): int =
  var d = distance(self, contact)
  result = bitsToDecimal(d)

echo("which kbucket? a a ", which_kbucket(anode, anode))
echo("which kbucket? self:a contact b ", which_kbucket(anode, bnode))


# a kbucket is just a seq
#

#echo("POW: ", pow2(0))
#echo("POW: ", pow2(1))
#echo("POW: ", pow2(2))
#echo("POW: ", pow2(3))
