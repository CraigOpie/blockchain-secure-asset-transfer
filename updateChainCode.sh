#!/bin/bash

# Setup environment variables
export PATH="/home/$USER/Developer/fabric-samples/bin:$PATH"
export FABRIC_CFG_PATH="/home/$USER/Developer/fabric-samples/config"
export CC_NAME="publicKeyStorage"
export CC_VERSION="1.3"
export CC_SEQ="1"
export CHANNEL_NAME="mychannel"
export ORDERER_CA="/home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
export PEER0_ORG1_CA="/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export PEER0_ORG2_CA="/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

# Define function to log in as Admin of Org1 or Org2
setupPeer() {
  MSP_PATH="/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/$1.example.com/users/Admin@$1.example.com/msp"
  PEER_ADDRESS="localhost:$2"

  export CORE_PEER_LOCALMSPID="${1^}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/$1.example.com/peers/peer0.$1.example.com/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="$MSP_PATH"
  export CORE_PEER_ADDRESS="$PEER_ADDRESS"

  echo "Switched to $1 Admin"
}

# Define function to install and approve chaincode
installAndApproveChaincode() {
  setupPeer $1 $2
  peer lifecycle chaincode install publicKeyStorage.tar.gz

  # Extract the package ID using more robust parsing
  PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | awk '/Package ID: / {print $3}' | cut -d ',' -f1)
  echo "Package ID: $PACKAGE_ID"

  # Check if the PACKAGE_ID is extracted correctly
  if [ -z "$PACKAGE_ID" ]; then
    echo "Error extracting Package ID"
    exit 1
  fi

  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C "$CHANNEL_NAME" --name "$CC_NAME" --version "$CC_VERSION" --sequence "$CC_SEQ" --package-id "$PACKAGE_ID" --waitForEvent
}

# Shutdown and restart network to clear previous setups
/home/$USER/Developer/fabric-samples/test-network/network.sh down
/home/$USER/Developer/fabric-samples/test-network/network.sh up createChannel -ca

# Register and enroll new user
fabric-ca-client register --caname ca-org1 --id.name $USER --id.secret user2pw --id.type client --tls.certfiles "$PEER0_ORG1_CA"
fabric-ca-client enroll -u https://$USER:user2pw@localhost:7054 --caname ca-org1 -M $FABRIC_CA_CLIENT_HOME/users/$USER@org1.example.com/msp --tls.certfiles "$PEER0_ORG1_CA"

# Package chaincode
peer lifecycle chaincode package publicKeyStorage.tar.gz --path . --lang node --label "$CC_NAME"_"$CC_VERSION"

# Install and approve chaincode on Org1
installAndApproveChaincode org1 7051

# Install and approve chaincode on Org2
installAndApproveChaincode org2 9051

# Commit chaincode on the channel
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C "$CHANNEL_NAME" --name "$CC_NAME" --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" --version "$CC_VERSION" --sequence "$CC_SEQ"

# Query committed chaincode on the channel
peer lifecycle chaincode querycommitted -C "$CHANNEL_NAME" --name "$CC_NAME"

# Change back to the user
cp /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp/config.yaml
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp
