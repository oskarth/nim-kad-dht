all: client server

client: src/client.nim src/service_pb.nim src/service_twirp.nim
	nim c -o:bin/client src/client.nim

server: src/server.nim src/service_pb.nim src/service_twirp.nim
	nim c -o:bin/server src/server.nim

%_pb.nim %_twirp.nim: %.proto
	../nimtwirp/nimtwirp/nimtwirp_build -I:. --out:. $^
