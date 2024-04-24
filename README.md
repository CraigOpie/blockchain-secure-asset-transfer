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

### 2. Download Fabric Samples

Clone the Fabric samples repository and install binaries:
```bash
mkdir /home/$USER/Developer && cd /home/$USER/Developer
curl -sSL https://bit.ly/2ysbOFE | bash -s
```

### 3. Set Environment PATH

Update your PATH to include the path to the downloaded Fabric binaries:
```bash
export PATH=/home/$USER/Developer/fabric-samples/bin:$PATH
```

### 4. Start the Network

Navigate to the test network directory and start up the network:
```bash
cd fabric-samples/test-network
./network.sh up createChannel -ca
```

### 5. Register and Enroll a New User

Set the Fabric CA client home directory:
```bash
export FABRIC_CA_CLIENT_HOME=/home/$USER/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com
```

Register and enroll a new user with your username:
```bash
fabric-ca-client register --caname ca-org1 --id.name ${USER} --id.secret user2pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
fabric-ca-client enroll -u https://${USER}:user2pw@localhost:7054 --caname ca-org1 -M ${FABRIC_CA_CLIENT_HOME}/users/${USER}@org1.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
```

### 6. Set Up Node.js Application

Create a new directory for your application and initialize it:
```bash
cd /home/$USER/Developer/blockchain-secure-asset-transfer
mkdir app && cd app
npm init -y
npm install fabric-network express --save
```

### 7. Start the Application

Run your application:
```bash
node app.js
```

Navigate to `http://localhost:3000/api/user` in your browser to interact with the Hyperledger Fabric network.

### Conclusion

This setup guide provides the necessary steps to get a Hyperledger Fabric network running on your system and to start a basic Node.js application that interacts with the network. Follow these instructions to ensure a correct setup and verify the network operation through the provided application endpoint.

### Troubleshooting

If you encounter any issues during setup, ensure all steps were followed correctly, particularly those involving path settings and permissions. Check Docker and Node.js logs for detailed error information. Revisit the commands for potential typos or missing steps.
