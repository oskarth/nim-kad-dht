import random
import strutils
import math

const
  alpha = 3 # degree of parallelism in network calls
  b = 3     # XXX: for testing
  #b = 160   # size of bits of keys used to identify nodes and data
  k = 20    # maximum number of contacts stored in a bucket

# TODO: tExpire, tRefresh, tReplicate, tRepublish constants
# TODO: A KBucket should contain Contacts, which in addition to NodeID also including network address

type
  NodeID* = array[b, int]
  KBucket = seq[NodeID] # max k items
  KBuckets = array[b, KBucket]

# XXX: How does random seed work? Seem to get same number here every run
proc genRandomNodeID(): NodeID =
  for i in 0..<result.len:
    result[i] = rand(1)

proc genNodeIDByInt(n: int): NodeID =
  var bs = n.toBin(b)
  for i in 0..<result.len:
    if char(bs[i]) == '1':
      result[i] = 1
    else:
      result[i] = 0

# XXX: This is for any bitstring, not just a NodeID
proc `$`(n: NodeID): string =
  result = "bs:"
  for i in 0..<n.len:
    result &= $n[i]

proc distance(a: NodeID, b: NodeID): NodeID = 
  for i in 0..<result.len:
    result[i] = a[i] xor b[i]

# Running stuff
#------------------------------------------------------------------------------

var an = genNodeIDByInt(0)
var bn = genNodeIDByInt(1)
var cn = genNodeIDByInt(2)
var dn = genNodeIDByInt(3)
var en = genNodeIDByInt(4)
var fn = genNodeIDByInt(5)
var gn = genNodeIDByInt(6)
var hn = genNodeIDByInt(7)

var an_contacts = [bn, cn, dn, en, fn, gn, hn]

proc which_kbucket(self: NodeID, contact: NodeID): int =
  var d = distance(self, contact)
  # Assuming bigendian, return most significant bit position
  for i in 0..<d.len:
    if d[i] == 1:
      return d.len - 1 - i
  # Self, not really a bucket
  return -1

var kb: KBucket
var kbs: KBuckets

for c in an_contacts:
  var i = which_kbucket(an, c)
  kbs[i].add(c)

echo("Keybuckets content for node a (self):")
for i in 0..<kbs.len:
  echo("bucket ", i, ": ", kbs[i])
