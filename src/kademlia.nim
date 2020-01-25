import random
#import math
import algorithm
import asyncdispatch
import os
import strutils
import tables

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

# Running stuff
#------------------------------------------------------------------------------

# TODO: Max 20 (e.g.) contacts in a key bucket; need eviction policy
#for c in an_contacts:
#  var i = which_kbucket(an, c)
#  kbs[i].add(c)
#

# Mocking RPC to node asking for FIND_NODE(id)
# NOTE: Slightly misleading name, it really find closest nodes
# MUST NOT return the originating node in its response
# Returns up to k contacts
# TODO: When being queried, this should also update that node's routing table
proc mockFindNode(node: ref Node, targetid: NodeID): Future[seq[Contact]] {.async.} =
  var nameStr = "[" & $node.name & "] "
  echo(nameStr, "mockFindNode: looking for up to k=", k, " contacts closest to: ", targetid)
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
  echo(nameStr, "Found up to k contacts: ", res)
  return res

# TODO: Refactor this functon, it is a monster atm
# > The search begins by selecting alpha contacts from the non-empty k-bucket closest to the bucket appropriate to the key being searched on. 
# XXX: Not convinced it is closest to bucket for other choices of n.
# TODO: Pick alpha candidates
#
# > The contact closest to the target key, closestNode, is noted.
proc iterativeFindNode(node: ref Node, targetid: NodeID, networkTable: Table[NodeID, ref Node]) {.async.} =
  var nameStr = "[" & $node.name & "] "
  echo(nameStr, "iterativeFindNode ", node.id, " ", targetid, " distance ", distance(node.id, targetid))
  var candidate: Contact
  var shortlist: Contacts
  var contacted: Contacts

  # XXX: Picking first candidate right now
  # TODO: Extend to pick alpha closest contacts
  for i in 0..node.kbuckets.len - 1:
    if node.kbuckets[i].len != 0:
      candidate = node.kbuckets[i][0]
      break
  echo(nameStr, "Found initial candidate: ", candidate)

  # We note the closest node we have
  var closestNode = candidate
  var movedCloser = true

  # Keep track of number of probed and active contacts
  # XXX: What counts as active? When should we reset this etc? For now hardcode
  var activeContacts = 0

  # ShortList of contacts to be contacted
  shortlist.add(candidate)

  # XXX: Remove me?
  proc numberOfContacts(node: ref Node): int =
    result = 0
    for i in 0..node.kbuckets.len - 1:
      result += node.kbuckets[i].len

  # XXX: Code dup, fix in-place sort fn
  proc distCmp(x, y: Contact): int =
    if distance(x.id, targetid) < distance(y.id, targetid): -1 else: 1

  # Take alpha candidates from shortlist, call them
  # TODO: Extend to send parallel async FIND_NODE requests here
  # TODO: Mark candidates in-flight?
  # The sequence of parallel searches is continued until either no node in the sets returned is closer than the closest node already seen or the initiating node has accumulated k probed and known to be active contacts.
  # XXX: Putting upper limit
  for i in 0..16:
    if ((movedCloser == false) and (shortlist.len() == 0)):
      # XXX: Not tested
      echo(namestr, "Didn't move lcoser to node and no nodes left to check in shortlist, breaking")
      break
    echo(namestr, "Active contacts: ", activeContacts, " desired: ", k)
    if (activeContacts >= k):
      echo(namestr, "Found desired number of active and probed contacts ", k, " breaking")
      break
    # Get contact from shortlist
    # XXX: Error handling and do first here?
    var c = shortlist[0]
    shortlist.delete(0)
    contacted.add(c)

    # Mock dial them them
    echo(namestr, "Mock dialing ", c)
    # XXX: Assuming c.id it exists in networkTable
    var resp = await mockFindNode(networkTable[c.id], targetid)
    echo(namestr, "Response ", resp)

    # Add new nodes as contacts, update activeContacts, shortlist and closestNode
    # XXX: Does it matter which order we update closestNode and shortlist in?
    # Only one, the one we probed - responses we don't know yet
    activeContacts += 1
    for c in resp:
      AddContact(node, c)
    echo(namestr, "Adding new nodes as contacts")
    echo node
    shortlist = resp
    shortlist.sort(distCmp)
    echo(namestr, "Update shortlist ", shortlist)

    # Update closest node
    var closestCandidate = findClosestNode(shortlist, targetid)
    var d1 = distance(closestCandidate.id, targetid)
    var d2 = distance(closestNode.id, targetid)
    if (d1 < d2):
      echo(namestr, "Found new closestNode ", closestCandidate)
      closestNode = closestcandidate
      movedCloser = true
    else:
      movedCloser = false

  # End when:
  # > The sequence of parallel searches is continued until either no node in the sets returned is closer than the closest node already seen or the initiating node has accumulated k probed and known to be active contacts.
  # > If a cycle doesn't find a closer node, if closestNode is unchanged, then the initiating node sends a FIND_* RPC to each of the k closest nodes that it has not already queried.
  # > At the end of this process, the node will have accumulated a set of k active contacts or (if the RPC was FIND_VALUE) may have found a data value. Either a set of triples or the value is returned to the caller.
  #
  # Still not clear on why we abort after k contacts, maybe evident in refreshBucket step

# TODO: refreshBucket - take random element and do find node on own id here
# XXX: Bug? It keeps taking random Bob instead of the much better Dan
# If I compile beforehand (vs interactive run) it gets different result...
proc refreshBucket(node: ref Node, idx: int, bucket: KBucket, networkTable: Table[NodeID, ref Node]) {.async.} =
  var nameStr = "[" & $node.name & "] "
  echo(nameStr, "Refreshing bucket ", idx)
  echo("Randomize moar")
  randomize()
  var c = bucket[rand(bucket.len-1)]
  echo(namestr, "Mock dialing random contact from bucket ", c)
  if not networkTable.hasKey(c.id):
    # XXX: Should we pick a new one here? Also disconnect logic, etc
    echo(namestr, "Can't find network address for contact ", c, " aborting")
  else:
    var resp = await mockFindNode(networkTable[c.id], c.id)
    echo(namestr, "Response ", resp)
    for c in resp:
      AddContact(node, c)
    echo node

# XXX: Refreshes _all_ buckets further away than "closest neighbor" - who is that?
# "occupied bucket with the lowest index", so isn't that just one? the "rightmost"/furthest-away one?
# Refreshing means picking a random ID from bucket and doing a node search for that ID
proc refreshMostDistantBucket(node: ref Node, networkTable: Table[NodeID, ref Node]) =
  var nameStr = "[" & $node.name & "] "
  echo(nameStr, "Refreshing most distant bucket")
  # Find most distant bucket
  for i in 0..node.kbuckets.len-1:
    var bucket = node.kbuckets[node.kbuckets.len-1-i]
    if bucket.len != 0:
      echo(nameStr, "Last bucket we want to refresh with random member ", bucket)
      discard refreshBucket(node, node.kbuckets.len-1-i, bucket, networkTable)
      break

# Setup existing network
#------------------------------------------------------------------------------

# RANDOMIZE
randomize()

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
var bob = newNode("Bob", genNodeIDByInt(6))
AddContactsFromAll(bob, @[3, 5, 7, 8])

# Charlie is 0011 (3) has full connectivity, and knows something Bob doesn't
var charlie = newNode("Charlie", genNodeIDByInt(3))
AddContactsFromAll(charlie, @[1, 2, 6, 8, 12])

# Dan doesn't have full connectivity
# Alice needs him for bucket refresh (via Bob)
var dan = newNode("Dan", genNodeIDByInt(5))
AddContactsFromAll(dan, @[6, 9, 14])

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
echo dan

# NOTE: This is used to mock RPC calls with objects
# TODO: Extend this to lookup address and RPC call
# For now this contains all relevant objects
var networkTable = {alice.id: alice, bob.id: bob, charlie.id: charlie, dan.id: dan}.toTable

# 3. iterativeFindNode(n) (where n is n.id)
# XXX: Should we use this return value? We are already updating alice node object...
discard iterativeFindNode(alice, alice.id, networkTable)

# 4. Refresh buckets further away
# "it refreshes all buckets further away than its closest neighbor, which will be in the occupied bucket with the lowest index."
refreshMostDistantBucket(alice, networkTable)

# Alice has joied the network.
# XXX: Sometimes they don't get new info, in which case Alice won't get full connectivity (50% atm)
# Solved by multiple bucket refreshes?
