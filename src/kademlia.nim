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

# Node lookup
# TODO: HERE ATM, mocking this
#
# Lets assume contact has kademlia connectivity, or atleast some nodes to give us
proc iterativeFindNode(node: ref Node, n: NodeID) =
  # First, find bucket with closest node (only 1 contact for now
  # Then all FIND_NODE(n) rpc
  # Select the first alpha (to start with 1)  contacts
  # Which bucket should we start to look in?
  echo("dist ", distance(node.self, n))
  # IF we were to find the node, which bucket would it be in?
  var candidate = which_kbucket(node, n)
  echo("which kbucket? ", which_kbucket(node, n))
  # This will return -1 as it is yourself
  if candidate == -1:
    # look in first bucket, then second etc
    # if this is a middle bucket then we need to branch out left and right (I think?)
    # TODO: HEREATM: Need to revisit this logic
    #
    # Then we can mock find node RPC as a function, perhaps async, get some nodes and keep going
    # To start with lets assume our contact has Kademlia connectivity and we want it to

  echo("FIND NODE ", n)
  # When response, call again (?)

# Join logic
#------------------------------------------------------------------------------

# 1. Generate node ID
var node = newNode(genNodeIDByInt(0))

# 2. Add known node contact c into appropriate bucket
var n1 = genNodeIDByInt(4) # third bucket
AddContact(node, n1, "")
echo node

# TODO 3. iterativeFindNode(n) (where n is n.self)
iterativeFindNode(node, node.self)

# TODO: 4. Refresh buckets further away
