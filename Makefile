all: node

node: src/node.nim src/service_pb.nim src/service_twirp.nim
	nim c -o:bin/node src/node.nim

%_pb.nim %_twirp.nim: %.proto
	../nimtwirp/nimtwirp/nimtwirp_build -I:. --out:. $^
