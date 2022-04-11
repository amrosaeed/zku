// Q3. Horizon Bridge



/* Check out Horizon repository. Briefly explain how the bridge process works (mention all necessary steps).

a) Comment the code for:

    - token locker on ethereum */


// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;
/// Encoder able to encode and decode arbitrarily nested arrays and structs
pragma experimental ABIEncoderV2;
/// Import harmony light client immplementation
import "./HarmonyLightClient.sol";
/// Import solidity immplementaion for merkle mountain ranges verifier
import "./lib/MMRVerifier.sol";
/// Import solidity immplmetation for the harmony prover
import "./HarmonyProver.sol";
/// Import harmony token locker
import "./TokenLocker.sol";
/// Import OwnableUpgradable.sol an openzeppelin audited lib Contract module which provides a basic access control mechanism, 
/// where there is an account (the ADMIN) that can be granted exclusive access to specific functions like pausing the light client, adding/removing relayers and reannouncing new admins.
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// Contract resposible for locking ETH tokens equivelent to ONE tokens to be bridged, it Inherits harmony TokenLocker contract 
contract TokenLockerOnEthereum is TokenLocker, OwnableUpgradeable {
    HarmonyLightClient public lightclient;

    mapping(bytes32 => bool) public spentReceipt;

    function initialize() external initializer {
        __Ownable_init();
    }

/// An external function can be called from other contracts via transactions attached to onlyOwner() modifier implicity within OwnableUpgradeable.sol
/// that allows only the to can change Instance of harmony's light client.
    function changeLightClient(HarmonyLightClient newClient)
        external
        onlyOwner
    {
        lightclient = newClient;
    }

/// An external function can be called from other contracts via transactions attached to onlyOwner() modifier implicity within OwnableUpgradeable.sol
/// that bind both addresses of the owner on the two chains
    function bind(address otherSide) external onlyOwner {
        otherSideBridge = otherSide;
    }

/// Function callable by the verifier "HVerifier", the function validate proof constraints aganist harmony light client instance emitted events stored HVM memory and execute proof 
/// by calling HarmonyProver.sol fraud proofs
    function validateAndExecuteProof(
        HarmonyParser.BlockHeader memory header,
        MMRVerifier.MMRProof memory mmrProof,
        MPT.MerkleProof memory receiptdata
    ) external {
        require(lightclient.isValidCheckPoint(header.epoch, mmrProof.root), "checkpoint validation failed");
        bytes32 blockHash = HarmonyParser.getBlockHash(header);
        bytes32 rootHash = header.receiptsRoot;
        (bool status, string memory message) = HarmonyProver.verifyHeader(
            header,
            mmrProof
        );
        require(status, "block header could not be verified");
        bytes32 receiptHash = keccak256(
            abi.encodePacked(blockHash, rootHash, receiptdata.key)
        );
        require(spentReceipt[receiptHash] == false, "double spent!");
        (status, message) = HarmonyProver.verifyReceipt(header, receiptdata);
        require(status, "receipt data could not be verified");
        spentReceipt[receiptHash] = true;
        uint256 executedEvents = execute(receiptdata.expectedValue);
        require(executedEvents > 0, "no valid event");
    }
}
