import asyncdispatch
import asynchttpserver
import httpclient
import json
import strutils

import service_pb

import nimtwirp/nimtwirp
import nimtwirp/errors

const
    DHTServicePrefix* = "/twirp/dht.DHTService/"

type
    DHTService* = ref DHTServiceObj
    DHTServiceObj* = object of RootObj
        PingImpl*: proc (service: DHTService, param: dht_PingRequest): Future[dht_PingResponse] {.gcsafe, closure.}

proc Ping*(service: DHTService, param: dht_PingRequest): Future[dht_PingResponse] {.async.} =
    if service.PingImpl == nil:
        raise newTwirpError(TwirpUnimplemented, "Ping is not implemented")
    result = await service.PingImpl(service, param)

proc newDHTService*(): DHTService =
    new(result)

proc handleRequest*(service: DHTService, req: Request): Future[nimtwirp.Response] {.async.} =
    let (contentType, methodName) = validateRequest(req, DHTServicePrefix)

    if methodName == "Ping":
        var inputMsg: dht_PingRequest

        if contentType == "application/protobuf":
            inputMsg = newdht_PingRequest(req.body)
        elif contentType == "application/json":
            let node = parseJson(req.body)
            inputMsg = parsedht_PingRequest(node)

        let outputMsg = await Ping(service, inputMsg)

        if contentType == "application/protobuf":
            return nimtwirp.newResponse(serialize(outputMsg))
        elif contentType == "application/json":
            return nimtwirp.newResponse(toJson(outputMsg))
    else:
        raise newTwirpError(TwirpBadRoute, "unknown method")


type
    DHTServiceClient* = ref object of nimtwirp.Client

proc newDHTServiceClient*(address: string, kind = ClientKind.Protobuf): DHTServiceClient =
    new(result)
    result.client = newHttpClient()
    result.kind = kind
    case kind
    of ClientKind.Protobuf:
        result.client.headers = newHttpHeaders({"Content-Type": "application/protobuf"})
    of ClientKind.Json:
        result.client.headers = newHttpHeaders({"Content-Type": "application/json"})
    result.address = address

proc Ping*(client: DHTServiceClient, req: dht_PingRequest): dht_PingResponse =
    var body: string
    case client.kind
    of ClientKind.Protobuf:
        body = serialize(req)
    of ClientKind.Json:
        body = $toJson(req)
    let resp = request(client, DHTServicePrefix, "Ping", body)
    case client.kind
    of ClientKind.Protobuf:
        result = newdht_PingResponse(resp.body)
    of ClientKind.Json:
        result = parsedht_PingResponse(parseJson(resp.body))

