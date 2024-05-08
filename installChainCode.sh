#!/bin/bash

# Setup env variables
export CC_NAME=publicKeyStorage
export CC_VERSION=1.0
export PATH=/home/$USER/Developer/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=/home/$USER/Developer/fabric-samples/config
export FABRIC_CA_CLIENT_HOME=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com
export CORE_PEER_TLS_ENABLED=true

# Setup org1 variables
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Start the network
/home/$USER/Developer/fabric-samples/test-network/network.sh down
/home/$USER/Developer/fabric-samples/test-network/network.sh up createChannel -ca

# Register and enroll a new user with your username
fabric-ca-client register --caname ca-org1 --id.name $USER --id.secret user2pw --id.type client --tls.certfiles /home/$USER/Developer/fabric-samples/test-network/organizations/fabric-ca/org1/tls-cert.pem
fabric-ca-client enroll -u https://$USER:user2pw@localhost:7054 --caname ca-org1 -M $FABRIC_CA_CLIENT_HOME/users/$USER@org1.example.com/msp --tls.certfiles /home/$USER/Developer/fabric-samples/test-network/organizations/fabric-ca/org1/tls-cert.pem
cp /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp/config.yaml
sed -i "s|^    mspConfigPath: msp|    mspConfigPath: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp|" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "/tls:/,/cert:/s/enabled:  false/enabled: true/" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "s|file: tls/server.crt|file: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt|" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "s|file: tls/server.key|file: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key|" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "s|file: tls/ca.crt|file: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt|" /home/$USER/Developer/fabric-samples/config/core.yaml

# Install chaincode on Org1's peer
peer lifecycle chaincode package publicKeyStorage.tar.gz --path /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript/ --lang node --label publicKeyStorage_1.0
peer lifecycle chaincode install publicKeyStorage.tar.gz
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep "$CC_NAME"_"$CC_VERSION" | awk -F "," '{print $1}' | awk '{print $3}')
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel --name publicKeyStorage --version 1.0 --sequence 1 --package-id $PACKAGE_ID --waitForEvent
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name publicKeyStorage --version 1.0 --sequence 1 --output json --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Setup org2 variables
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

# Install chaincode on Org2's peer
peer lifecycle chaincode package publicKeyStorage.tar.gz --path /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript --lang node --label publicKeyStorage_1.0
peer lifecycle chaincode install publicKeyStorage.tar.gz
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep "$CC_NAME"_"$CC_VERSION" | awk -F "," '{print $1}' | awk '{print $3}')
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel --name publicKeyStorage --version 1.0 --sequence 1 --package-id $PACKAGE_ID --waitForEvent
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name publicKeyStorage --version 1.0 --sequence 1 --output json --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Default back to org1 variables
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Commit the chaincode
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel --name publicKeyStorage --peerAddresses localhost:7051 --tlsRootCertFiles /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --version 1.0 --sequence 1
peer lifecycle chaincode querycommitted -C mychannel --name publicKeyStorage

# Change back to the user
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp