#!/bin/bash

# Install required files
cd /home/$USER/Developer
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s
mkdir -p /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript
cd /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript
npm install fabric-contract-api fabric-shim --save
cd /home/$USER/Developer/blockchain-secure-asset-transfer/app
cp -f /home/$USER/Developer/blockchain-secure-asset-transfer/publicKeyStorage.js /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript/
cp -f /home/$USER/Developer/blockchain-secure-asset-transfer/package.json /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript/
/home/$USER/Developer/blockchain-secure-asset-transfer/installChainCode.sh
