#import random
#import math
import algorithm
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
  Contact* = object
    id*: NodeID
    address*: string
  Contacts = seq[Contact] # no limit, convenience type
  KBucket = seq[Contact] # TODO: max k items
  KBuckets = array[b, KBucket]
  Node = object
    # Local human-friendly name, no significance
    name: string
    id: NodeID
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

proc `<`(a, b: NodeID): bool =
  for i in 0..<a.len:
    if a[i] < b[i]:
      return true
    if b[i] < a[i]:
      return false
  return false

proc nodeHasKademliaConnectivity(n: ref Node): bool =
  for kb in n.kbuckets:
    if kb.len == 0:
      return false
  return true

# XXX: This string building is ugly, use printf style
proc `$`(n: ref Node): string =
  var res = $n.name & " (" & $n.id & ")\n"
  var res2 = "Kademlia connectivity: " & $nodeHasKademliaConnectivity(n) & "\n"
  var sep = "----------------------------------------------------------------\n"
  var buckets = ""
  for i in 0..<n.kbuckets.len:
    var bucket = $"bucket " & $i & $": " & $n.kbuckets[i] & "\n"
    buckets = buckets & bucket
  var total = "\n" & res & res2 & sep & buckets
  return total

proc which_kbucket(node: ref Node, contact: NodeID): int =
  var d = distance(node.id, contact)
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

proc newNode(name: string, id: NodeID): ref Node =
  var kbs: KBuckets
  new(result)
  result.name = name
  result.id = id
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
var bob = newNode("Bob", genNodeIDByInt(6))

# Mocking RPC to node asking for FIND_NODE(id)
# NOTE: Slightly misleading name, it really find closest nodes
# MUST NOT return the originating node in its response
# Returns up to k contacts
proc mockFindNode(node: ref Node, targetid: NodeID): Future[seq[Contact]] {.async.} =
  echo("[Bob] mockFindNode: looking for up to k=", k, " contacts closest to: ", targetid)
  # Simulating some RPC latency
  os.sleep(1000)

  # Find up to k closest nodes to target
  #
  # NOTE: Bruteforcing my sorting all contacts, not efficient but least error-prone for now.
  # TODO: Make this more efficient, sketch (might be wrong, verify):
  # 0) If reach k contacts at any point, return
  # 1) Look in kb=which_kbucket(node, targetid)
  # 2) Then traverse backward from kb to key bucket 0
  # 3) If still not reached k, go upwards in kbucket from kb+1
  # 4) If still not k contacts, return anyway
  # Look at other implementations to see how this is done
  var contacts: seq[Contact]
  for kb in node.kbuckets:
    for contact in kb:
      contacts.add(contact)

  proc distCmp(x, y: Contact): int =
    if distance(x.id, targetid) < distance(y.id, targetid): -1 else: 1

  contacts.sort(distCmp)
  var res: seq[Contact]
  for c in contacts:
    if res.len == k:
      break
    res.add(c)
  echo("[Bob] Found up to k contacts: ", res)
  return res

# > The search begins by selecting alpha contacts from the non-empty k-bucket closest to the bucket appropriate to the key being searched on. 
# XXX: Not convinced it is closest to bucket for other choices of n.
# TODO: Pick alpha candidates
#
# > The contact closest to the target key, closestNode, is noted.
proc iterativeFindNode(node: ref Node, n: NodeID) {.async.} =
  echo("[Alice] iterativeFindNode ", node.id, " ", n, " distance ", distance(node.id, n))
  var candidate: Contact
  var bucket_index = which_kbucket(node, n)

  # XXX: Picking first candidate right now
  # TODO: Extend to pick alpha closest contacts
  for i in 0..node.kbuckets.len - 1:
    if node.kbuckets[i].len != 0:
      candidate = node.kbuckets[i][0]
      break
  echo("[Alice] Found candidate: ", candidate)

  # We note the closest node we have
  var closestNode = candidate

  # ShortList of contacts to be contacted
  # NOTE: Why not use a set type? Is Shortlist ordered?
  # Can't use native set type, needs to be of certain size https://nim-lang.org/docs/manual.html#types-set-type
  # What's a better way to do this in Nim? Set semantics better
  # I guess we can make a hacky set type
  var shortlist: Contacts
  shortlist.add(candidate)

  # TODO: Extend to send parallel async FIND_NODE requests here
  # TODO: Look up Shortlist candidate network adress, then call procedure that way
  # Mark in-flight?
  # XXX: Hardcode bob here

  var resp = await mockFindNode(bob, n)
  echo("[Alice] Response ", resp)
  # TODO: Add to shortlist and keep going

# Join logic
#------------------------------------------------------------------------------

# Second example: Bob is 0110 (6) and has full connectivity
# Already part of network
var n2 = genNodeIDByInt(7) # 0111
var n3 = genNodeIDByInt(5) # 0101
var n4 = genNodeIDByInt(3) # 0011
var n5 = genNodeIDByInt(8) # 1000
# TODO: Add at least fake addresses and make sure added at right time
AddContact(bob, n2, "")
AddContact(bob, n3, "")
AddContact(bob, n4, "")
AddContact(bob, n5, "")
echo bob

# 1. Generate node ID
var node = newNode("Alice", genNodeIDByInt(0))

# 2. Add known node contact c into appropriate bucket
var n1 = genNodeIDByInt(6) # third bucket
AddContact(node, n1, "")
echo node

# TODO 3. iterativeFindNode(n) (where n is n.id)
discard iterativeFindNode(node, node.id)
# TODO: HEREATM: Need to revisit this logic
#
# Then we can mock find node RPC as a function, perhaps async, get some nodes and keep going
# To start with lets assume our contact has Kademlia connectivity and we want it to

# I dont think Alice has joined network yet.

# TODO: 4. Refresh buckets further away
#
#
