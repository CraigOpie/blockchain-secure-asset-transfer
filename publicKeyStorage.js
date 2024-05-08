'use strict';

const { Contract } = require('fabric-contract-api');

class PublicKeyStorage extends Contract {

    async initLedger(ctx) {
        console.info('Chaincode initialization');
    }

    async storePublicKey(ctx, userId, publicKey) {
        console.info('Received storePublicKey request');
        
        const identity = ctx.clientIdentity;
        console.info(`User ID from clientIdentity: ${identity.getAttributeValue('hf.EnrollmentID')}`);
        console.info(`Expected User ID: ${userId}`);

        if (!identity.assertAttributeValue('hf.EnrollmentID', userId)) {
            console.error('Authorization failed');
            throw new Error('Unauthorized: Only the user can store their public key');
        }

        const key = `PUBLICKEY_${userId}`;
        let data = {
            publicKey: publicKey,
            owner: userId,
            timestamp: new Date().toISOString(),
            type: 'RSA-4096',
        };

        console.info(`Attempting to store public key for user: ${userId} with key: ${key}`);
        await ctx.stub.putState(key, Buffer.from(JSON.stringify(data)));
        console.info(`Successfully stored data: ${JSON.stringify(data)}`);
        return JSON.stringify(data);
    }

    async retrievePublicKey(ctx, userId) {
        const key = `PUBLICKEY_${userId}`;
        console.info(`Retrieving public key for user: ${userId} with key: ${key}`);

        const dataAsBytes = await ctx.stub.getState(key);
        if (!dataAsBytes || dataAsBytes.length === 0) {
            console.error(`No data found for key: ${key}`);
            throw new Error(`The public key for ${userId} does not exist.`);
        }
        
        console.info(`Public key retrieved for user: ${userId}`);
        return dataAsBytes.toString();
    }

    async retrieveAllPublicKeys(ctx) {
        let allResults = [];
        const startKey = '';
        const endKey = '';
        const allKeysIterator = await ctx.stub.getStateByRange(startKey, endKey);
        while (true) {
            const res = await allKeysIterator.next();
            if (res.value && res.value.value.toString()) {
                const Key = res.value.key;
                let Record;
                try {
                    Record = JSON.parse(res.value.value.toString('utf8'));
                } catch (err) {
                    console.log(err);
                    Record = res.value.value.toString('utf8');
                }
                allResults.push({ Key, Record });
            }
            if (res.done) {
                await allKeysIterator.close();
                console.info(allResults);
                return JSON.stringify(allResults);
            }
        }
    }
}

module.exports = PublicKeyStorage;