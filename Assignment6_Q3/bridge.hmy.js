// Q3. Horizon Bridge



/* Check out Horizon repository. Briefly explain how the bridge process works (mention all necessary steps).

a) Comment the code for:

    - test contract */

/// use Nodejs/Javascript test contracts i.e. TokenLockerOnEthereum and to read Blocks instances 
const rlp = require('rlp');
const headerData = require('./headers.json');
const transactions = require('./transaction.json');
const { rpcWrapper, getReceiptProof } = require('../scripts/utils');

const { expect } = require('chai');

let MMRVerifier, HarmonyProver;
let prover, mmrVerifier;

/// Convert a hex string to a byte array required by crypto-js immplementation
function hexToBytes(hex) {
    for (var bytes = [], c = 0; c < hex.length; c += 2)
        bytes.push(parseInt(hex.substr(c, 2), 16));
    return bytes;
}

/// Gather tests into separate groupings within the same file, even multiple nested levels enumerated by the "it" functions
describe('HarmonyProver', function () {
/// Async block await until the promise returns a result
    beforeEach(async function () {
    /// await MMRVerifier out of the contract factory
        MMRVerifier = await ethers.getContractFactory("MMRVerifier");
        /// await deploying MMRVerifier 
        mmrVerifier = await MMRVerifier.deploy();
        /// await deploying mmrVerifier
        await mmrVerifier.deployed();

        // await HarmonyProver.link('MMRVerifier', mmrVerifier);
        HarmonyProver = await ethers.getContractFactory(
            "HarmonyProver",
            {
                libraries: {
                    MMRVerifier: mmrVerifier.address
                }
            }
        );
        prover = await HarmonyProver.deploy();
        /// await deploying prover until parsing the block header
        await prover.deployed();
    });
    /// Block of it function to treat parsing rlp block header as async function block await until the relevant promise returns a result
    it('parse rlp block header', async function () {
        let header = await prover.toBlockHeader(hexToBytes(headerData.rlpheader));
        expect(header.hash).to.equal(headerData.hash);
    });
    /// Block of it function to treat parsing the transaction recipt proof as async function block await until the relevant promise returns a result
    it('parse transaction receipt proof', async function () {
        let callback = getReceiptProof;
        let callbackArgs = [
            process.env.LOCALNET,
            prover,
            transactions.hash
        ];
        let isTxn = true;
        let txProof = await rpcWrapper(
            transactions.hash,
            isTxn,
            callback,
            callbackArgs
        );
        console.log(txProof);
        expect(txProof.header.hash).to.equal(transactions.header);

        // let response = await prover.getBlockRlpData(txProof.header);
        // console.log(response);

        // let res = await test.bar([123, "abc", "0xD6dDd996B2d5B7DB22306654FD548bA2A58693AC"]);
        // // console.log(res);
    });
});

let TokenLockerOnEthereum, tokenLocker;
let HarmonyLightClient, lightclient;
/// Gather tests into separate groupings within the same file, even multiple nested levels enumerated by the "it" functions, this time for TokenLockerOnEthereum
describe('TokenLocker', function () {
/// Async block await until the promise returns a result
    beforeEach(async function () {
        /// await TokenLockerOnEthereum out of the contract factory
        TokenLockerOnEthereum = await ethers.getContractFactory("TokenLockerOnEthereum");
        /// await deploying mmrVerifier for TokenLocker
        tokenLocker = await MMRVerifier.deploy();
        /// await deploying TokenLocker till binding tokenLoker address
        await tokenLocker.deployed();

        await tokenLocker.bind(tokenLocker.address);

/// await block for HarmonyProver is commented out ///

        // // await HarmonyProver.link('MMRVerifier', mmrVerifier);
        // HarmonyProver = await ethers.getContractFactory(
        //     "HarmonyProver",
        //     {
        //         libraries: {
        //             MMRVerifier: mmrVerifier.address
        //         }
        //     }
        // );
        // prover = await HarmonyProver.deploy();
        // await prover.deployed();

        
    });
    
/// Test results

    it('issue map token test', async function () {
        
    });

    it('lock test', async function () {
        
    });

    it('unlock test', async function () {
        
    });

    it('light client upgrade test', async function () {
        
    });
});
