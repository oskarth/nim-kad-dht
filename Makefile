all: client server kademlia node ping

kademlia: src/kademlia.nim
	nim c -o:bin/kademlia src/kademlia.nim

client: src/client.nim src/service_pb.nim src/service_twirp.nim
	nim c -o:bin/client src/client.nim

server: src/server.nim src/service_pb.nim src/service_twirp.nim
	nim c -o:bin/server src/server.nim

node: src/node.nim src/service_pb.nim src/service_twirp.nim
	nim c --threads -o:bin/node src/node.nim

chat: src/chat.nim
	nim c --threads:on -o:bin/ping src/chat.nim 

ping: src/ping.nim
	nim c --threads:on -o:bin/ping src/ping.nim 

%_pb.nim %_twirp.nim: %.proto
	../nimtwirp/nimtwirp/nimtwirp_build -I:. --out:. $^
