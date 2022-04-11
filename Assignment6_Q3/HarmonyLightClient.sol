// Q3. Horizon Bridge



/* Check out Horizon repository. Briefly explain how the bridge process works (mention all necessary steps).

a) Comment the code for:

    - harmony light client */


// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;
/// Encoder able to encode and decode arbitrarily nested arrays and structs
pragma experimental ABIEncoderV2; 
/// Import HarmonyParser.sol, lib SafeCast and openzeppelin libraries
import "./HarmonyParser.sol";
import "./lib/SafeCast.sol";
/// Import SafeMathUpgradeable openzeppelin library used for safely convert between the all different signed and unsigned numeric types.
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
/// An openzeppelin module contract to Grants `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE` to the admin account.;
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
/// An initializer module contract that will be deployed behind a proxy have many drawbacks, (TODO) CAUTION: When used with inheritance, 
/// manual care must be taken to not invoke a parent initializer twice like HarmonyLightClient.
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";


/// Immplementation of harmony's light client as solidity contract on ethereum
/// inherits form Initializable, PausableUpgradeable and AccessControlUpgradeable contracts
contract HarmonyLightClient is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
/// SafeCast module used for safely convert between the all different signed and unsigned numeric types.
    using SafeCast for *;
/// Since pragma is under 0.8.0 "SafeMathUpgradeable" is a solidity math library 
/// especially designed to support safe math operations for uint256, it prevents 
/// overflow with types like uint256
    using SafeMathUpgradeable for uint256;

/// "struct BlockHeader" compose a new data type BlockHeader that contains different data types, 
/// Representing Harmony's chain instance block header.
    struct BlockHeader {
        bytes32 parentHash; /// byte32 type variable representing hash of the parent block.
        bytes32 stateRoot;  /// byte32 type variable representing state root at current block.
        bytes32 transactionsRoot; /// byte32 type variable representing Merkle root of transaction.
        bytes32 receiptsRoot;
        uint256 number;  /// byte256 type variable representing block number.
        uint256 epoch;   /// byte256 type variable representing epoch time.
        uint256 shard;   /// byte256 type variable representing shard of consensus.
        uint256 time;    /// byte32 type variable representing timestamp of the block.
        bytes32 mmrRoot; /// byte32 type variable representing Merkle Mountain Range tree root.
        bytes32 hash;  /// byte32 type variable representing hash of the block.
    }

/// Intializing an event to be inheritable for the lightclient contract it stores the 
/// arguments passed in transaction logs in Ethereum chain. 
/// checkpoint is a block in the first slot of an epoch, if there were no blocks it proceeds to 
/// the next slot of the epoch
    event CheckPoint(
        bytes32 stateRoot,
        bytes32 transactionsRoot,
        bytes32 receiptsRoot,
        uint256 number,
        uint256 epoch,
        uint256 shard,
        uint256 time,
        bytes32 mmrRoot,
        bytes32 hash
    );
/// Inatializing the checkpoint event to 
    BlockHeader firstBlock;
    BlockHeader lastCheckPointBlock;

    // epoch to block numbers, as there could be >=1 mmr entries per epoch
    mapping(uint256 => uint256[]) epochCheckPointBlockNumbers;

    // block number to BlockHeader
    mapping(uint256 => BlockHeader) checkPointBlocks;

    mapping(uint256 => mapping(bytes32 => bool)) epochMmrRoots;

    uint8 relayerThreshold;
    
/// Intializing an event of the new relayer threshold to be inheritable for the lightclient 
/// contract it stores the arguments passed in transaction logs in Ethereum chain.
    event RelayerThresholdChanged(uint256 newThreshold);
/// Intializing an event of the recent relayer added address to be inheritable for the lightclient 
/// contract it stores the arguments passed in transaction logs in Ethereum chain.
    event RelayerAdded(address relayer);
/// Intializing an event of the recent relayer removed address to be inheritable for the  
/// lightclient contract it stores the arguments passed in transaction logs in Ethereum chain.
    event RelayerRemoved(address relayer);

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

/* After Importing different librares and assigning it's modules use for contracts variables types.
   It structs a composable data type blockheader.
   Declaring events that report to the contract dependent on argument passed in EVM tx log
   A set of modifiers instantiated to change the behaviour of the function to which it is attached.
   A group of functions to set the rules for admins, relayers and instatiate light client instance.
*/

/// A modifier to be attached to an internal onlyAdmin() function, uses "msg.sender" call function
/// to check that the sender is the admin and got the default admin rule.
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender doesn't have admin role");
        _;
    }
    
/// A modifier to be attached to an internal onlyRelayer() function, uses "msg.sender" call function
/// to check that the sender is the relayer and got the default relayer rule.
    modifier onlyRelayers() {
        require(hasRole(RELAYER_ROLE, msg.sender), "sender doesn't have relayer role");
        _;
    }

/// An external function can be called from other contracts via transactions attached to 
/// onlyAdmin() modifier, to make sure that only the admin can pause the lightclient.
    function adminPauseLightClient() external onlyAdmin {
        _pause();
    }

/// An external function can be called from other contracts via transactions attached to 
/// onlyAdmin() modifier, to make sure that only the admin can UNpause the lightclient.
    function adminUnpauseLightClient() external onlyAdmin {
        _unpause();
    }

/// An external function can be called from other contracts via transactions attached to 
/// onlyAdmin() modifier, to re nounce new admin with its address, it requires that current 
/// cannot re nounce himself by calling function "msg.sender" and having the default admin rule
/// and renouncing new admin by having the grant role and passing his default admin role to 
/// the new admin.
    function renounceAdmin(address newAdmin) external onlyAdmin {
        require(msg.sender != newAdmin, 'cannot renounce self');
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/// An external function can be called from other contracts via transactions attached to 
/// onlyAdmin() modifier, allows only the admin to change the relayer threshold, and emit 
/// the changes to harmony's EVM with the new threshold.
    function adminChangeRelayerThreshold(uint256 newThreshold) external onlyAdmin {
        relayerThreshold = newThreshold.toUint8();
        emit RelayerThresholdChanged(newThreshold);
    }

/// An external function can be called from other contracts via transactions attached to 
/// onlyAdmin() modifier, allows only the admin to add a relayer with it's address, require 
/// the relayer has no RELAYER_ROLE attached to his address he's trying to sign with, by 
/// granting the RELAYER_ROLE to his address, and emit the changes to harmony's EVM.
    function adminAddRelayer(address relayerAddress) external onlyAdmin {
        require(!hasRole(RELAYER_ROLE, relayerAddress), "addr already has relayer role!");
        grantRole(RELAYER_ROLE, relayerAddress);
        emit RelayerAdded(relayerAddress);
    }

/// An external function can be called from other contracts via transactions attached to 
/// onlyAdmin() modifier, allows only the admin to remove a relayer with it's address, require 
/// the relayer has RELAYER_ROLE attached to his address he's trying to sign with, by 
/// revoking the RELAYER_ROLE to his address, and emit the changes to harmony's EVM.
    function adminRemoveRelayer(address relayerAddress) external onlyAdmin {
        require(hasRole(RELAYER_ROLE, relayerAddress), "addr doesn't have relayer role!");
        revokeRole(RELAYER_ROLE, relayerAddress);
        emit RelayerRemoved(relayerAddress);
    }

/// A external function to be called form other contracts Intialize RLP serialized first header, 
/// the intial relayers and intial relayer threshold, the initializer used HarmonyParser to 
/// translate the RLP serialized blockheader and store it memory.
    function initialize(
        bytes memory firstRlpHeader,
        address[] memory initialRelayers,
        uint8 initialRelayerThreshold
    ) external initializer {
        HarmonyParser.BlockHeader memory header = HarmonyParser.toBlockHeader(
            firstRlpHeader
        );
        
 /// Building the instance of the canonical chain of blocks depending on the header of epoch 
 /// block wether it's the first or the last in the relevent epoch for Harmony's fast state
 /// syncronization mechanisim.       
        firstBlock.parentHash = header.parentHash;// Initialize parentHash field of the block @ the first Block with the Appended parnetHash attribute of header.
        firstBlock.stateRoot = header.stateRoot;// Initialize stateRoot field of the block @ the first Block with the Appended stateRoot attribute of header.
        firstBlock.transactionsRoot = header.transactionsRoot;// Initialize transactionsRoot field of the block @ the first Block with the Appended transactionsRoot attribute of header.
        firstBlock.receiptsRoot = header.receiptsRoot;// Initialize receiptsRoot field of the block @ the first Block with the Appended receiptsRoot attribute of header.
        firstBlock.number = header.number;// Initialize number field of the block @ the first Block with the Appended number attribute of header.
        firstBlock.epoch = header.epoch;// Initialize epoch field of the block @ the first Block with the Appended epoch attribute of header.
        firstBlock.shard = header.shardID;// Initialize number shardID of the block @ the first Block with the Appended shardID attribute of header.
        firstBlock.time = header.timestamp;// Initialize timestamp field of the block @ the first Block with the Appended number timestamp of header.
        firstBlock.mmrRoot = HarmonyParser.toBytes32(header.mmrRoot);// Initialize mmRoot field of the block @ the first Block with the Appended mmRoot attribute of header.
        firstBlock.hash = header.hash;// Initialize hash field of the block @ the first Block with the Appended hash attribute of header.
/// Setup the checkpoint to the first block.        
        epochCheckPointBlockNumbers[header.epoch].push(header.number);
        checkPointBlocks[header.number] = firstBlock;

        epochMmrRoots[header.epoch][firstBlock.mmrRoot] = true;
/// Initialize the intial relayer threshold as the relayer threshold
        relayerThreshold = initialRelayerThreshold;
/// Setting-up the admin role using "msg.sender" call function to grant roles of the relayers
/// starting by a list its first member is the intial relayer.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i; i < initialRelayers.length; i++) {
            grantRole(RELAYER_ROLE, initialRelayers[i]);
        }

    }

/// Submitting checkpoint instance rlpHeader to only relayers in case light client 
/// not paused by the admin
    function submitCheckpoint(bytes memory rlpHeader) external onlyRelayers whenNotPaused {
        HarmonyParser.BlockHeader memory header = HarmonyParser.toBlockHeader(
            rlpHeader
        );
/// Building the instance of the checkpoint depending on the header of epoch 
/// block wether it's the first or the last in the relevent epoch for Harmony's fast state
/// syncronization mechanisim.   
        BlockHeader memory checkPointBlock;
        
        checkPointBlock.parentHash = header.parentHash;// Initialize parentHash field of the block @ checkpoint with the Appended parnetHash attribute of header.
        checkPointBlock.stateRoot = header.stateRoot;// Initialize stateRoot field of the block @ checkpoint with the Appended stateRoot attribute of header.
        checkPointBlock.transactionsRoot = header.transactionsRoot;// Initialize transactionsRoot field of the block @ checkpoint with the Appended transactionsRoot attribute of header.
        checkPointBlock.receiptsRoot = header.receiptsRoot;// Initialize receiptsRoot field of the block @ checkpoint with the Appended receiptsRoot attribute of header.
        checkPointBlock.number = header.number;// Initialize number field of the block @ checkpoint with the Appended number attribute of header.
        checkPointBlock.epoch = header.epoch;// Initialize epoch field of the block @ checkpoint with the Appended epoch attribute of header.
        checkPointBlock.shard = header.shardID;// Initialize shardID field of the block @ checkpoint with the Appended shardID attribute of header.
        checkPointBlock.time = header.timestamp;// Initialize timestamp field of the block @ checkpoint with the Appended timestamp attribute of header.
        checkPointBlock.mmrRoot = HarmonyParser.toBytes32(header.mmrRoot);// Initialize mmrRoot field of the block @ checkpoint with the Appended mmrRoot attribute of header.
        checkPointBlock.hash = header.hash;// Initialize hash field of the block @ checkpoint with the Appended hash attribute of header.
        
        epochCheckPointBlockNumbers[header.epoch].push(header.number);
        checkPointBlocks[header.number] = checkPointBlock;

        epochMmrRoots[header.epoch][checkPointBlock.mmrRoot] = true;
        
        /// emit to CheckPoint event to notify the transaction initiator about the actions  
        /// performed by the called function.
        emit CheckPoint(
            checkPointBlock.stateRoot,
            checkPointBlock.transactionsRoot,
            checkPointBlock.receiptsRoot,
            checkPointBlock.number,
            checkPointBlock.epoch,
            checkPointBlock.shard,
            checkPointBlock.time,
            checkPointBlock.mmrRoot,
            checkPointBlock.hash
        );
    }

// Get the latest checkpoit at the end of the epoch
    function getLatestCheckPoint(uint256 blockNumber, uint256 epoch)
        public
        view
        returns (BlockHeader memory checkPointBlock)
    {
        require(
            epochCheckPointBlockNumbers[epoch].length > 0,
            "no checkpoints for epoch"
        );
        uint256[] memory checkPointBlockNumbers = epochCheckPointBlockNumbers[epoch];
        uint256 nearest = 0;
        for (uint256 i = 0; i < checkPointBlockNumbers.length; i++) {
            uint256 checkPointBlockNumber = checkPointBlockNumbers[i];
            if (
                checkPointBlockNumber > blockNumber &&
                checkPointBlockNumber < nearest
            ) {
                nearest = checkPointBlockNumber;
            }
        }
        checkPointBlock = checkPointBlocks[nearest];
    }

// Announce validity of the checkpoit and return epoch Mmr roots
    function isValidCheckPoint(uint256 epoch, bytes32 mmrRoot) public view returns (bool status) {
        return epochMmrRoots[epoch][mmrRoot];
    }
}
