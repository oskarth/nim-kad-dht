import asynchttpserver
import asyncdispatch

import nimtwirp/nimtwirp
import nimtwirp/errors

import strformat
import strutils

import service_pb
import service_twirp


proc PingImpl(service: DHTService, pingReq: dht_PingRequest): Future[dht_PingResponse] {.async.} =
    if pingReq.id <= 0:
        raise newTwirpError(TwirpInvalidArgument, "Invalid request id!")

    result = dht_PingResponse()
    result.id = pingReq.id

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

waitFor server.serve(Port(8000), handler)
