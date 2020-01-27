import random
import libp2p/[peerinfo, crypto/crypto, peer]

let seckey = PrivateKey.random(RSA) # use a random key for peer id

var peerId = PeerInfo.init(seckey) # create a peer id and assign

let id = peerId.peerId.pretty
echo "PeerID: " & id

# TODO: Persist key to disk 
