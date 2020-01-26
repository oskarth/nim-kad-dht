import asynchttpserver
import asyncdispatch

import nimtwirp/nimtwirp
import nimtwirp/errors

import strformat
import strutils

import service_pb
import service_twirp


proc PingImpl(service: DHTService, pingReq: dht_PingRequest): Future[dht_PingResponse] {.async.} =
    echo("Got a ping request")
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

proc handler*(req: Request) {.async.} =
    # Each service will have a generated handleRequest() proc which takes the
    # service object and a asynchttpserver.Request object and returns a
    # Future[nimtwirp.Response].
    echo("handler hit")
    var fut = handleRequest(service, req)
    yield fut
    if fut.failed:
        await respond(req, nimtwirp.newResponse(fut.readError()))
    else:
        await respond(req, fut.read())

proc startServer*(portInt: int) {.async.} =
  echo "Starting server"
  discard server.serve(Port(portInt), handler)
