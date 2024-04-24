const { Wallets, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const app = require('express')();
const port = 3000;

app.get('/api/user', async (req, res) => {
    try {
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        const certPath = '/home/parallels/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User2@org1.example.com/msp/signcerts/cert.pem';
        const keyDirectoryPath = '/home/parallels/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User2@org1.example.com/msp/keystore';
        
        const privateKeyPath = fs.readdirSync(keyDirectoryPath)[0];
        const privateKey = fs.readFileSync(path.join(keyDirectoryPath, privateKeyPath)).toString();
        const certificate = fs.readFileSync(certPath).toString();

        const identityLabel = 'user2';
        const identity = {
            credentials: {
                certificate,
                privateKey,
            },
            mspId: 'Org1MSP',
            type: 'X.509',
        };

        await wallet.put(identityLabel, identity);

        const ccpPath = '/home/parallels/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/connection-org1.json';
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: identityLabel, discovery: { enabled: true, asLocalhost: true } });

        res.send('Connected to Hyperledger Fabric');
    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
        res.status(500).send(`Failed to submit transaction: ${error.message}`);
    }
});

app.listen(port, () => console.log(`Server running at http://localhost:${port}`));