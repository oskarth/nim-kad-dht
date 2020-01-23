#import random
#import math
import asyncdispatch
import strutils
import os

const
  # XXX: These values are used for testing
  alpha = 1
  b = 4
  k = 2

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
  ShortList = array[alpha, Contact]
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
# XXX: moving up declaration to mock RPC (hardcoded hack)
var bob = newNode(genNodeIDByInt(6))

# Mocking RPC to node asking for FIND_NODE(id)
# Returns up to k contacts
proc mockFindNode(node: ref Node, nodeid: NodeID): Future[seq[Contact]] {.async.} =
  echo("mockFindNode, I am ", node.self, " what k-triplets close to ", nodeid)
  var bi = which_kbucket(node, nodeid)
  var kbucket = node.kbuckets[bi]
  echo("closest kbucket is bucket ", bi, " with ", kbucket)
  os.sleep(1000)
  # TODO: If there aren't k contacts in that bucket, we should return adjacent buckets
  # TODO: HERE ATM, k=2 case
  # QQQ
  # We should return more nodes here, does it make sense to extend? Lets do k=2
  return kbucket

# > The search begins by selecting alpha contacts from the non-empty k-bucket closest to the bucket appropriate to the key being searched on. 
# XXX: Not convinced it is closest to bucket for other choices of n.
# TODO: Pick alpha candidates
#
# > The contact closest to the target key, closestNode, is noted.
proc iterativeFindNode(node: ref Node, n: NodeID) {.async.} =
  echo("iterativeFindNode ", node.self, " ", n, " distance ", distance(node.self, n))
  var candidate: Contact
  var bucket_index = which_kbucket(node, n)

  for i in 0..node.kbuckets.len - 1:
    if node.kbuckets[i].len != 0:
      candidate = node.kbuckets[i][0]
      break
  echo("Found candidate: ", candidate)

  var closestNode = candidate
  var shortlist: Shortlist = [candidate]
  # TODO: Send parallel async FIND_NODE reqs here
  # XXX: Hardcode bob here, normally it'd look up candidate network address and then call proc
  var resp = await mockFindNode(bob, n)
  echo("RESP ", resp)
  # TODO: Add to shortlist and keep going

proc nodeHasKademliaConnectivity(n: ref Node): bool =
  for kb in n.kbuckets:
    if kb.len == 0:
      return false
  return true

# Join logic
#------------------------------------------------------------------------------

# Second example: Bob is 0110 (6) and has full connectivity
# Already part of network
echo("Bob time - Kademlia connectivity")
var n2 = genNodeIDByInt(7) # 0111
var n3 = genNodeIDByInt(5) # 0101
var n4 = genNodeIDByInt(3) # 0011
var n5 = genNodeIDByInt(8) # 1000
AddContact(bob, n2, "")
AddContact(bob, n3, "")
AddContact(bob, n4, "")
AddContact(bob, n5, "")
echo("Bob connected? ", nodeHasKademliaConnectivity(bob))
echo bob

# 1. Generate node ID
var node = newNode(genNodeIDByInt(0))

# 2. Add known node contact c into appropriate bucket
var n1 = genNodeIDByInt(6) # third bucket
AddContact(node, n1, "")
echo node

# TODO 3. iterativeFindNode(n) (where n is n.self)
discard iterativeFindNode(node, node.self)
# TODO: HEREATM: Need to revisit this logic
#
# Then we can mock find node RPC as a function, perhaps async, get some nodes and keep going
# To start with lets assume our contact has Kademlia connectivity and we want it to

# I dont think Alice has joined network yet.

# TODO: 4. Refresh buckets further away
#
#
