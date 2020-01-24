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

# Don't care about address for now
proc `$`(c: Contact): string =
  result = $c.id

# XXX: distance is not actually nodeID but bs
proc distance(a: NodeID, b: NodeID): NodeID = 
  for i in 0..<result.len:
    result[i] = a[i] xor b[i]

proc distance(a, b: Contact): NodeID =
  return distance(a.id, b.id)

proc `<`(a, b: NodeID): bool =
  for i in 0..<a.len:
    if a[i] < b[i]:
      return true
    if b[i] < a[i]:
      return false
  return false

proc `<`(a, b: Contact): bool =
  return a.id < b.id

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
# XXX: Can we get rid of this? Lets see with network mocking
proc AddContact(node: ref Node, nodeid: NodeID, address: string) =
  var c = Contact(id: nodeid, address: "")
  var i = which_kbucket(node, c.id)
  node.kbuckets[i].add(c)

proc AddContact(node: ref Node, c: Contact) =
  var i = which_kbucket(node, c.id)
  node.kbuckets[i].add(c)

proc AddContacts(node: ref Node, contacts: Contacts) =
  for c in contacts:
    AddContact(node, c)

proc newNode(name: string, id: NodeID): ref Node =
  var kbs: KBuckets
  new(result)
  result.name = name
  result.id = id
  result.kbuckets = kbs

# XXX: This is definitely not most elegant way of doing this
proc findClosestNode(contacts: Contacts, targetid: NodeId): Contact =
  var temp: seq[Contact]
  for c in contacts:
    temp.add(c)

  proc distCmp(x, y: Contact): int =
    if distance(x.id, targetid) < distance(y.id, targetid): -1 else: 1

  temp.sort(distCmp)
  result = temp[0]


# Sketch Contacts Set type
# What operations do we want?
# - Add to set
# - Remove from set
# - Difference of set (don't touch seen ones)
# - Ideally idempotent etc
# - For now maybe all we need is difference
# XXX: Do later
#proc difference(a, b: seq[Contact]): seq[Contact] =
#  sorted_a
#  sorted_b
#  for i in 0..<a.len:
#

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
proc iterativeFindNode(node: ref Node, targetid: NodeID) {.async.} =
  echo("[Alice] iterativeFindNode ", node.id, " ", targetid, " distance ", distance(node.id, targetid))
  var candidate: Contact

  # XXX: Picking first candidate right now
  # TODO: Extend to pick alpha closest contacts
  for i in 0..node.kbuckets.len - 1:
    if node.kbuckets[i].len != 0:
      candidate = node.kbuckets[i][0]
      break
  echo("[Alice] Found initial candidate: ", candidate)

  #inFlight
  #contactedContacts

  # We note the closest node we have
  var closestNode = candidate

  # ShortList of contacts to be contacted
  # NOTE: Why not use a set type? Is Shortlist ordered?
  # Can't use native set type, needs to be of certain size https://nim-lang.org/docs/manual.html#types-set-type
  # What's a better way to do this in Nim? Set semantics better
  # I guess we can make a hacky set type
  var shortlist: Contacts
  var contacted: Contacts
  shortlist.add(candidate)

  # TODO: Extend to send parallel async FIND_NODE requests here
  # TODO: Look up Shortlist candidate network adress, then call procedure that way
  # TODO: Mark candidates in-flight?
  # XXX: Hardcode bob here, not using candidate list
  var c = shortlist.pop()
  # Mark contact as contacted
  contacted.add(c)
  echo("[Alice] Mock dialing Bob")
  var resp = await mockFindNode(bob, targetid)
  echo("[Alice] Response from Bob ", resp)

  # Add new nodes as contacts
  for c in resp:
    AddContact(node, c)
  echo("[Alice] Adding new nodes as contacts")
  echo node

  # XXX: Assuming we contacted first one
  shortlist = resp
  # This list consists of contacts closest to the target
  echo("[Alice] Update shortlist ", shortlist)

  # XXX: Code dup, fix in-place sort fn
  proc distCmp(x, y: Contact): int =
    if distance(x.id, targetid) < distance(y.id, targetid): -1 else: 1
  shortlist.sort(distCmp)

  var closestCandidate = findClosestNode(shortlist, targetid)
  var d1 = distance(closestCandidate.id, targetid)
  var d2 = distance(closestNode.id, targetid)
  if (d1 < d2):
    echo("[Alice] Found new closestNode ", closestCandidate)
    closestNode = closestcandidate

  # XXX: Does it matter which order we update closestNode and shortlist in?

  # Round 2
  # XXX: Just want to do first, eh
  c = shortlist[0]
  shortlist.delete(0)
  #c = shortlist.pop()
  contacted.add(c)
  echo("[Alice] Update shortlist ", shortlist)

  echo("[Alice] About to call ", c)
  # TODO: Call Charlie

  # TODO: These other node don't exist, mock them?
  # Update closestNode...let's make more mock nodes, specifically one that is closer
  # Continued until we found k nodes (why? not longer? until we have full connectivity?)
  # What does paper say?
  # "continues until it has received from k closest contacts", how do we know? bleh, sleep

  # End condition:
  #
  # > The sequence of parallel searches is continued until either no node in the sets returned is closer than the closest node already seen or the initiating node has accumulated k probed and known to be active contacts.
  # > If a cycle doesn't find a closer node, if closestNode is unchanged, then the initiating node sends a FIND_* RPC to each of the k closest nodes that it has not already queried.
  # > At the end of this process, the node will have accumulated a set of k active contacts or (if the RPC was FIND_VALUE) may have found a data value. Either a set of triples or the value is returned to the caller.

# Setup existing network
#------------------------------------------------------------------------------

# Setup existing network first, then Alice joins
# Global view for testing, assumes all possible nodes exist
var all_contacts: Contacts
for i in 0..15:
  all_contacts.add(Contact(id: genNodeIDByInt(i), address: ""))

proc AddContactsFromAll(node: ref Node, indices: seq[int]) =
  for i in indices:
    AddContact(node, Contact(id: genNodeIDByInt(i), address: ""))

# Alice hasn't joined yet but she will be 0

# Bob is 0110 (6) and has full connectivity
# TODO: Add at least fake addresses and make sure added at right time
AddContactsFromAll(bob, @[3, 5, 7, 8])

# Charlie is 0011 (3) has full connectivity, and knows something Bob doesn't
var charlie = newNode("Charlie", genNodeIDByInt(3))
AddContactsFromAll(charlie, @[1, 2, 6, 8, 12])

# TODO: Dan

# Join logic
#------------------------------------------------------------------------------

# 1. Generate node ID
var alice = newNode("Alice", genNodeIDByInt(0))

# 2. Add known node contact c into appropriate bucket
# This is Bob
AddContact(alice, all_contacts[6])

echo "Printing network"
echo alice
echo bob
echo charlie

# TODO 3. iterativeFindNode(n) (where n is n.id)
discard iterativeFindNode(alice, alice.id)
# TODO: HEREATM: Need to revisit this logic
#
# Then we can mock find node RPC as a function, perhaps async, get some nodes and keep going
# To start with lets assume our contact has Kademlia connectivity and we want it to

# I dont think Alice has joined network yet.

# TODO: 4. Refresh buckets further away
#
#
