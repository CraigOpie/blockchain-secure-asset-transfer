# Hyperledger Fabric Network Setup Guide

This guide provides step-by-step instructions on how to set up a Hyperledger Fabric network using the Fabric samples. It includes the setup of a basic application to interact with the blockchain using the Fabric Network SDK.

## Prerequisites

Before you begin, make sure you have the following installed on your system:
- Docker and Docker Compose
- curl (for downloading necessary files)
- Node.js and npm (for running the application)
- jq (for data management)

## Installation Steps

### 1. Configure Docker Group

Add your user to the Docker group to manage Docker as a non-root user:
```bash
sudo usermod -aG docker $USER
```

After running this command, **restart your system** to apply the changes.

### 2 Setup the Fabric Network

### 2.1 Download Fabric Samples

Clone the Fabric samples repository and install binaries:
```bash
mkdir /home/$USER/Developer && cd /home/$USER/Developer
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s
mkdir -p /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript
cd /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript
npm install fabric-contract-api fabric-shim --save
```

#### 2.2 Implement Chaincode for Storing Public Keys

Create the chaincode named `publicKeyStorage.js`:
```javascript
'use strict';

const { Contract } = require('fabric-contract-api');

class PublicKeyStorage extends Contract {

    async initLedger(ctx) {
        console.info('Chaincode initialization');
    }

    async storePublicKey(ctx, userId, publicKey) {
        const identity = ctx.clientIdentity;
        if (!identity.assertAttributeValue('hf.EnrollmentID', userId)) {
            throw new Error('Unauthorized: Only the user can store their public key');
        }

        let data = {
            publicKey: publicKey,
            owner: userId,
            timestamp: new Date().toISOString(),
            type: 'RSA-4096',
        };

        console.info(`Storing public key for user: ${userId}`);
        await ctx.stub.putState(userId, Buffer.from(JSON.stringify(data)));
        console.info(`Stored data: ${JSON.stringify(data)}`);
        return JSON.stringify(data);
    }

    async retrievePublicKey(ctx, userId) {
        const dataAsBytes = await ctx.stub.getState(userId);
        if (!dataAsBytes || dataAsBytes.length === 0) {
            console.error(`No data found for ${userId}`);
            throw new Error(`The public key for ${userId} does not exist.`);
        }
        console.info(`Data retrieved for ${userId}: ${dataAsBytes.toString()}`);
        return dataAsBytes.toString();
    }
}

module.exports = PublicKeyStorage;
```

Update the Package.json file to point to your chaincode:
```json
{
  "name": "javascript",
  "version": "1.0.0",
  "description": "Public Key Storage Chaincode",
  "main": "publicKeyStorage.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "fabric-chaincode-node start"
  },
  "keywords": [],
  "author": "Craig Opie",
  "license": "ISC",
  "dependencies": {
    "fabric-contract-api": "^2.5.4",
    "fabric-shim": "^2.5.4"
  }
}
```

### 3. Set Environment PATH

Update your PATH to include the path to the downloaded Fabric binaries:
```bash
export PATH=/home/$USER/Developer/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=/home/$USER/Developer/fabric-samples/config
export FABRIC_CA_CLIENT_HOME=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
```

### 4. Start the Network

Navigate to the test network directory and start up the network:
```bash
cd /home/$USER/Developer/fabric-samples/test-network
./network.sh down
./network.sh up createChannel -ca
```

### 5. Register and Enroll a New User

Register and enroll a new user with your username:
```bash
fabric-ca-client register --caname ca-org1 --id.name $USER --id.secret user2pw --id.type client --tls.certfiles /home/$USER/Developer/fabric-samples/test-network/organizations/fabric-ca/org1/tls-cert.pem
fabric-ca-client enroll -u https://$USER:user2pw@localhost:7054 --caname ca-org1 -M $FABRIC_CA_CLIENT_HOME/users/$USER@org1.example.com/msp --tls.certfiles /home/$USER/Developer/fabric-samples/test-network/organizations/fabric-ca/org1/tls-cert.pem
sed -i "s|^    mspConfigPath: msp|    mspConfigPath: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp|" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "/tls:/,/cert:/s/enabled:  false/enabled: true/" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "s|file: tls/server.crt|file: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt|" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "s|file: tls/server.key|file: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key|" /home/$USER/Developer/fabric-samples/config/core.yaml
sed -i "s|file: tls/ca.crt|file: /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt|" /home/$USER/Developer/fabric-samples/config/core.yaml
```

### 6. Package and Install the Chain Code

Install chaincode on Org1's peer
```bash
peer lifecycle chaincode package publicKeyStorage.tar.gz --path . --lang node --label publicKeyStorage_1.0
peer lifecycle chaincode install publicKeyStorage.tar.gz
peer lifecycle chaincode queryinstalled
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel --name publicKeyStorage --version 1.0 --sequence 1 --package-id <PACKAGE_ID> --waitForEvent
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name publicKeyStorage --version 1.0 --sequence 1 --output json --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

Expect:
```bash
{
        "approvals": {
                "Org1MSP": true,
                "Org2MSP": false
        }
}
```

Install chaincode on Org2's peer
```bash
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode package publicKeyStorage.tar.gz --path /home/$USER/Developer/fabric-samples/test-network/chaincode/publicKeyStorage/javascript --lang node --label publicKeyStorage_1.0
peer lifecycle chaincode install publicKeyStorage.tar.gz
peer lifecycle chaincode queryinstalled
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel --name publicKeyStorage --version 1.0 --sequence 1 --package-id <PACKAGE_ID> --waitForEvent
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name publicKeyStorage --version 1.0 --sequence 1 --output json --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

Expect:
```bash
{
        "approvals": {
                "Org1MSP": true,
                "Org2MSP": true
        }
}
```

Set back to Org1 and commit the chaincode
```bash
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel --name publicKeyStorage --peerAddresses localhost:7051 --tlsRootCertFiles /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --version 1.0 --sequence 1
peer lifecycle chaincode querycommitted -C mychannel --name publicKeyStorage
cp /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp/config.yaml
export CORE_PEER_MSPCONFIGPATH=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp
```

Expect:
```bash
Committed chaincode definition for chaincode 'publicKeyStorage' on channel 'mychannel':
Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc, Approvals: [Org1MSP: true, Org2MSP: true]
```

Create and write the public key to the blockchain:
```bash
openssl x509 -text -noout -in /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/$USER@org1.example.com/msp/signcerts/cert.pem
openssl genpkey -algorithm RSA -out /home/$USER/Developer/blockchain-secure-asset-transfer/app/private_key.pem -pkeyopt rsa_keygen_bits:4096
public_key=$(cat /home/$USER/Developer/blockchain-secure-asset-transfer/app/public_key.pem | base64 | tr -d '\n')
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /home/$USER/Developer/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n publicKeyStorage --peerAddresses localhost:7051 --tlsRootCertFiles /home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt -c "{\"function\":\"storePublicKey\",\"Args\":[\"$USER\", \"$public_key\"]}"
peer chaincode query -C mychannel -n publicKeyStorage -c "{\"Args\":[\"retrievePublicKey\", \"$USER\"]}"
```


<PACKAGE_ID>
### 7. Set Up Node.js Application

Create a new directory for your application and initialize it:
```bash
cd /home/$USER/Developer/blockchain-secure-asset-transfer
mkdir app && cd app
npm init -y
npm install fabric-network express --save
```

### 8. Start the Application

Run your application:
```bash
node app.js
```

Navigate to `http://localhost:3000/api/user` in your browser to interact with the Hyperledger Fabric network.

### Conclusion

This setup guide provides the necessary steps to get a Hyperledger Fabric network running on your system and to start a basic Node.js application that interacts with the network. Follow these instructions to ensure a correct setup and verify the network operation through the provided application endpoint.

### Troubleshooting

If you encounter any issues during setup, ensure all steps were followed correctly, particularly those involving path settings and permissions. Check Docker and Node.js logs for detailed error information. Revisit the commands for potential typos or missing steps.
