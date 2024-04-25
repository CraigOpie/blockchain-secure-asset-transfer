const express = require('express');
const { Wallets, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

app.use(bodyParser.urlencoded({ extended: true }));

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        const walletPath = path.join(__dirname, 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        const userIdentity = await wallet.get(username);

        if (!userIdentity) {
            res.status(401).send('Login failed: Username not found');
            return;
        }

        const ccpPath = '/home/parallels/Developer/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/connection-org1.json';
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));
        
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: username, discovery: { enabled: true, asLocalhost: true } });
        
        res.redirect('/dashboard');
    } catch (error) {
        console.error(`Login error: ${error}`);
        res.status(500).send('Login error. Please try again.');
    }
});

app.get('/dashboard', (req, res) => {
    res.send("Welcome to your dashboard! You're logged in.");
});

app.get('/api/user', async (req, res) => {
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
});

app.listen(port, () => console.log(`Server running at http://localhost:${port}`));