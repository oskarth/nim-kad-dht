import asynchttpserver
import asyncdispatch

import nimtwirp/nimtwirp
import nimtwirp/errors

import os

import strformat
import strutils

import service_pb
import service_twirp

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
    var fut = handleRequest(service, req)
    yield fut
    if fut.failed:
        await respond(req, nimtwirp.newResponse(fut.readError()))
    else:
        await respond(req, fut.read())

echo "Starting server"

# Run server in background
discard server.serve(Port(8080), handler)

# In background, also do loop
proc timeLoop() {.async.} =
  while true:
    echo("TODO: Ping here")
    os.sleep(1000)

discard timeLoop()

echo("Leaving procss hanging")

runForever()
