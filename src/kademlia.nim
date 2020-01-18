#import random
#import math
import strutils

const
  # XXX: These values are used for testing
  #alpha = 1
  b = 3

  #alpha = 3 # degree of parallelism in network calls
  #b = 160   # size of bits of keys used to identify nodes and data

  #k = 20    # maximum number of contacts stored in a bucket

# TODO: tExpire, tRefresh, tReplicate, tRepublish constants
# TODO: A KBucket should contain Contacts, which in addition to NodeID also including network address

type
  NodeID* = array[b, int]
  #KBucket = seq[NodeID] # max k items
  Contact* = object
    id*: NodeID
    address*: string
  KBucket = seq[Contact] # max k items
  KBuckets = array[b, KBucket]
  Node = object
    self: NodeID
    kbuckets: KBuckets

# XXX: How does random seed work? Seem to get same number here every run
#proc genRandomNodeID(): NodeID =
#  for i in 0..<result.len:
#    result[i] = rand(1)

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

proc `$`(n: ref Node): string =
  var res = "Self (" & $n.self & "):\n--------------------\n"
  for i in 0..<n.kbuckets.len:
    res = res & $"bucket " & $i & $": " & $n.kbuckets[i] & "\n"
  return res

proc which_kbucket(node: ref Node, contact: NodeID): int =
  var d = distance(node.self, contact)
  # Assuming bigendian, return most significant bit position
  for i in 0..<d.len:
    if d[i] == 1:
      return d.len - 1 - i
  # Self, not really a bucket
  return -1

# XXX: Assuming kb isn't full
proc AddContact(node: ref Node, nodeid: NodeID, address: string) =
  var c = Contact(id: nodeid, address: "")
  var i = which_kbucket(node, c.id)
  node.kbuckets[i].add(c)

proc newNode(self: NodeID): ref Node =
  var kbs: KBuckets
  new(result)
  result.self = self
  result.kbuckets = kbs

# Running stuff
#------------------------------------------------------------------------------
#

#var an = genNodeIDByInt(0)
#var bn = genNodeIDByInt(1)
#var cn = genNodeIDByInt(2)
#var dn = genNodeIDByInt(3)
#var en = genNodeIDByInt(4)
#var fn = genNodeIDByInt(5)
#var gn = genNodeIDByInt(6)
#var hn = genNodeIDByInt(7)
#
#var an_nodes = [bn, cn, dn, en, fn, gn, hn]
#

#for id in an_nodes:
#  AddContact(id, "")

# TODO: Max 20 (e.g.) contacts in a key bucket; need eviction policy
#for c in an_contacts:
#  var i = which_kbucket(an, c)
#  kbs[i].add(c)
#

# Join logic, how does it work? From http://xlattice.sourceforge.net/components/protocol/kademlia/specs.html
#
#A node joins the network as follows:
#
#    if it does not already have a nodeID n, it generates one
#    it inserts the value of some known node c into the appropriate bucket as its first contact
#    it does an iterativeFindNode for n
#    it refreshes all buckets further away than its closest neighbor, which will be in the occupied bucket with the lowest index.
#
#If the node saved a list of good contacts and used one of these as the "known node" it would be consistent with this protocol.
#
#

# Node lookup

# Join logic
#------------------------------------------------------------------------------

# 1. Generate node ID
var node = newNode(genNodeIDByInt(0))

# 2. Add known node contact c into appropriate bucket
var n1 = genNodeIDByInt(4) # third bucket
AddContact(node, n1, "")
echo node
