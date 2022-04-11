// Q3. Horizon Bridge



/* Check out Horizon repository. Briefly explain how the bridge process works (mention all necessary steps).

a) Comment the code for:

    - token locker on harmony */


// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;
/// Encoder able to encode and decode arbitrarily nested arrays and structs
pragma experimental ABIEncoderV2;
/// Import SafeMathUpgradeable openzeppelin library used for safely convert between the all different signed and unsigned numeric types.
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
/// Import ethereum light client immplmetation
import "./EthereumLightClient.sol";
/// Import solidity immplmetation for the ethereum prover
import "./EthereumProver.sol";
/// Import ethereum token locker
import "./TokenLocker.sol";

/// Contract resposible for locking ONE tokens equivelent to ETH tokens to be bridged, it Inherits ethereum TokenLocker contract
contract TokenLockerOnHarmony is TokenLocker, OwnableUpgradeable {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    EthereumLightClient public lightclient;

    mapping(bytes32 => bool) public spentReceipt;

    function initialize() external initializer {
        __Ownable_init();
    }

/// An external function can be called from other contracts via transactions attached to onlyOwner() modifier implicity within OwnableUpgradeable.sol
/// that allows only the to can change Instance of Ethereum's light client.
    function changeLightClient(EthereumLightClient newClient)
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

/// Function callable by the verifier "EVerifier", the function validate proof constraints aganist ethereum light client instance emitted events stored in calldata, memory and execute proof 
/// by calling EthereumProver.sol fraud proofs
    function validateAndExecuteProof(
        uint256 blockNo,
        bytes32 rootHash,
        bytes calldata mptkey,
        bytes calldata proof
    ) external {
        bytes32 blockHash = bytes32(lightclient.blocksByHeight(blockNo, 0));
        require(
            lightclient.VerifyReceiptsHash(blockHash, rootHash),
            "wrong receipt hash"
        );
        bytes32 receiptHash = keccak256(
            abi.encodePacked(blockHash, rootHash, mptkey)
        );
        require(spentReceipt[receiptHash] == false, "double spent!");
        bytes memory rlpdata = EthereumProver.validateMPTProof(
            rootHash,
            mptkey,
            proof
        );
        spentReceipt[receiptHash] = true;
        uint256 executedEvents = execute(rlpdata);
        require(executedEvents > 0, "no valid event");
    }
}
