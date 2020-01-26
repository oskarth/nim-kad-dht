import asynchttpserver
import asyncdispatch
import threadpool

import nimtwirp/nimtwirp
import nimtwirp/errors

import os

import strformat
import strutils

import service_pb
import service_twirp

# Parse arguments
# TODO: Use proper optparse etc
echo paramCount(), " ", paramStr(1)
var name = paramStr(1)
var servePort: int
var clientPort: int
if name == "alice":
  echo("8000")
  servePort = 8000
  clientPort = 8001
elif name == "bob":
  echo("8001")
  servePort = 8001
  clientPort = 8000
else:
  echo("unknown name")
  quit(1)

# XXX: Client or server? Should be server
proc PingImpl(service: DHTService, pingReq: dht_PingRequest): Future[dht_PingResponse] {.async.} =
    if pingReq.id <= 0:
        raise newTwirpError(TwirpInvalidArgument, "Invalid request id!")

    result = dht_PingResponse()
    result.id = pingReq.id
    echo("Got a ping, responding with a pong")

var
    server = newAsyncHttpServer()
    service {.threadvar.}: DHTService

service = newDHTService()
service.PingImpl = PingImpl

proc handler(req: Request) {.async.} =
    # Each service will have a generated handleRequest() proc which takes the
    # service object and a asynchttpserver.Request object and returns a
    # Future[nimtwirp.Response].
    echo("handler received req")
    var fut = handleRequest(service, req)
    yield fut
    if fut.failed:
        await respond(req, nimtwirp.newResponse(fut.readError()))
    else:
        await respond(req, fut.read())

echo "Starting server"
asyncCheck server.serve(Port(servePort), handler)
echo "Server running in background"

runForever()

#proc makePingReq() {.async.} =
#  echo "Starting client"
#  os.sleep(3000) # time for other node to wake up
#  # Connect to existing server, later each p2p node
#  echo("Connecting to " & $clientPort)
#  let client = newDHTServiceClient("http://localhost:" & $clientPort)
#  echo("Got me a client ", $clientPort)
#
#  echo("makePingReq")
#  os.sleep(1000)
#
#  var pingRequest = dht_PingRequest()
#  try:
#    pingRequest.id = 1
#  except:
#    echo("invalid id")
#    quit(QuitFailure)
#
#  echo("Making a ping request with id ", pingRequest.id)
#
#  try:
#    echo("Pinging me a client - XXX hangs here")
#    #XXX: Is this sync? Which Ping?
#    let pingResp = Ping(client, pingRequest)
#    echo(&"**************I got a pong: {pingResp.id}")
#  except Exception as e:
#    echo(&"error: {e.msg}")
#
#proc pingLoop() {.async.} =
#  while true:
#    echo("pre Pinging")
#    # Use spawn etc?
#    os.sleep(500)
#    # XXX: Here atm, need to figure out threads etc.
#    # XXX: Wouldn't it make more sense to have each
#    # server client connection in sep thread?
#    discard spawn makePingReq()
#    echo("post Pinging")
#
#echo "Starting server"
#discard server.serve(Port(servePort), handler)
#
## Client ping test in background
##waitFor makePingReq()
##waitFor pingLoop()
#
#discard pingLoop()
#
## IF Alice runs client mode it can't process server requests... why?
#
#echo("Leaving procss hanging")
#
#runForever()
#
#echo("Hello")
#
# HERE ATM
# TODO: FindNode request to server
# TODO: make src/node.nim that has a client and server, and allows client part to send in background while getting requests - i.e. alice and bob sleep 5s, then both ping each other every 2 seconds
# TODO: Then, start to hook up to kademlia
# TODO: Make parameterized who this is based on arg, then 81 or 82
