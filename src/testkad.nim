import unittest, sequtils, options
import chronos
import kad_setup
#export standard_setup

# TODO: HERE ATM, fix errors and get basic test file to compile

# I think we can do even more basic tests, like xor distance
#
proc generateNodes*(num: Natural, gossip: bool = false): seq[Switch] =
  for i in 0..<num:
    result.add(newKadSwitch())

suite "Kademlia":
  test "Kademlia 1+1":
    check:
      1+1 == 2
 
  test "Kademlia basic find node (XXX: bad test)":
    proc runTests(): Future[bool] {.async.} =
      var completionFut = newFuture[bool]()
      proc handler(data: seq[byte]) {.async, gcsafe.} =
        # TODO: Return something, anything, here
        # TODO: Then return closest known node here
        completionFut.complete(true)

      # TODO: Ensure these nodes have right characteristics
      var nodes = generateNodes(2)
      var awaiters: seq[Future[void]]
      # TODO: Ensure start method
      awaiters.add((await nodes[0].start()))
      awaiters.add((await nodes[1].start()))

      # We aren't subscribing to anything here, it is an RPC
      # What does subscribeNodes(nodes) do?
      # Where does handler come in?
      # await nodes[1].subscribe("foobar", handler)
      # TODO: Use start handler here
      await sleepAsync(1000.millis)

      # Not publishing either, but sending to nodes[1]
      # TODO: Look at publish interface and make (direct) send one
      # TODO: This should be protobuf message
      #await nodes[0].send("find_node(1)")

      result = await completionFut
      # TODO: Ensure stop methods
      await allFutures(nodes[0].stop(), nodes[1].stop())
      await allFutures(awaiters)

    check:
      waitFor(runTests()) == true
