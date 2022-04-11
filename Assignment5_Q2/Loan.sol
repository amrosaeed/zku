/* Q.2 Aztec

AZTEC protocol utilizes a set of zero-knowledge proofs to define a confidential transaction protocol, to shield both native assets and assets that conform with certain standards (e.g. ERC20) on a Turing-complete general-purpose computation.

     Q2.2:
     [Infrastructure Track Only] Using the loan application as a reference point, briefly explain how AZTEC can be used to create a private loan application on the blockchain highlighting the benefits and challenges. In the Loan Application, explain the Loan.sol and LoanDapp.sol file (comment inline) */

// Define solidity version
pragma solidity >= 0.5.0 <0.7.0;
// Import required libraries

// The standard interface of a mintable confidential asset, where 
// The ownership values and transfer values are encrypted.
import "@aztec/protocol/contracts/ERC1724/ZkAssetMintable.sol";
// A utility library that extracts user-readable information from AZTEC proof outputs.
import "@aztec/protocol/contracts/libs/NoteUtils.sol";
// An interface defining the ZkAsset standard.
import "@aztec/protocol/contracts/interfaces/IZkAsset.sol";
// A utility .sol
import "./LoanUtilities.sol";


// Inherit ZkAssetMintable contract as Interface for Loan contract.
contract Loan is ZkAssetMintable {
// Use libraries SafeMath, NoteUtils, and LoanVariables for typing different 
// variables types.
  using SafeMath for uint256;
  using NoteUtils for bytes;
  using LoanUtilities for LoanUtilities.LoanVariables;
  LoanUtilities.LoanVariables public loanVariables;

// Declare settlementToken a public variable of IZkAsset Interface type.
  IZkAsset public settlementToken;
  // [0] interestRate
  // [1] interestPeriod
  // [2] duration
  // [3] settlementCurrencyId
  // [4] loanSettlementDate
  // [5] lastInterestPaymentDate address public borrower;

// Declare two variables lender & brrower of type address and with public visibility.
  address public lender;
  address public borrower;
// Mapping into a hash table consists of Keys fo type address to 
// Key_values of bytes for users, naming the mapping variable to "lenderApproval".
  mapping(address => bytes) lenderApprovals;
  
// Declare an event "LoanPayment", it stores the arguments passed 
// "string paymentType, uint256 lastInterestPaymentDate" in transaction logs.
  event LoanPayment(string paymentType, uint256 lastInterestPaymentDate);
// Declare an event "LoanDefault"
  event LoanDefault();
// Declare an event "LoanRepaid"
  event LoanRepaid();
// A note struct which stores an a variable "owner" of type address 
// and a variable "noteHash" of type bytes32.
  struct Note {
    address owner;
    bytes32 noteHash;
  }


// Function "_noteCodeToStruct" stored in EVM memory a data structure of 
// name "note" of data type "bytes" that dont read or modify the state, 
// it only uses local variables as "address owner, bytes32 noteHash" 
// and returns the owner and the notehash as a Note struct and save it in 
// EVM memory as variable codedNote.

// Note: In the case the compiler running this function throws any kind of errors, 
// it will indicate the function is functioning as supposed.
  function _noteCoderToStruct(bytes memory note) internal pure returns (Note memory codedNote) {
      (address owner, bytes32 noteHash,) = note.extractNote();
      return Note(owner, noteHash );
  }

// Constructor of visibility public used to initialize state variables 
// of The standard interface of a mintable confidential asset ZkAssetMintable, 
// which by it's turn inherts ZkAssetMintableBase to finally initialize the 
// the state variables of this contract.
  constructor(
    bytes32 _notional,
    uint256[] memory _loanVariables,
    address _borrower,
    address _aceAddress,
    address _settlementCurrency
   ) public ZkAssetMintable(_aceAddress, address(0), 1, true, false) {
      loanVariables.loanFactory = msg.sender;
      loanVariables.notional = _notional;
      loanVariables.id = address(this);
      loanVariables.interestRate = _loanVariables[0];
      loanVariables.interestPeriod = _loanVariables[1];
      loanVariables.duration = _loanVariables[2];
      loanVariables.borrower = _borrower;
      borrower = _borrower;
      loanVariables.settlementToken = IZkAsset(_settlementCurrency);
      loanVariables.aceAddress = _aceAddress;
  }


// Function "requestAccess()" that address the mapping variable "lenderApprovals"
// when it has called by [msg.sender] from address started by prefix '0x'.
  function requestAccess() public {
    lenderApprovals[msg.sender] = '0x';
  }

// Function "approveAccess()" that address the mapping variable's "lenderApprovals" 
// hash table {[_lender],[_sharedSecret]}.
// The function has both arguments [address _lender, bytes memory _sharedSecret],
// the lender address and an internal EVM memory "_sharedSecret" of type bytes.
  function approveAccess(address _lender, bytes memory _sharedSecret) public {
    lenderApprovals[_lender] = _sharedSecret;
  }


/* After the above 2 functions "requestAccess()" & "approveAccess()" for authenticating AZTEC protocol users, the coming 6 functions shape the contract utility.

  // [0] function settleLoan()
  // [1] function confidentialMint()
  // [2] function withdrawInterest()
  // [3] function adjustInterestBalance()
  // [4] function repayLoan()
  // [5] function markLoanAsDefault() */
  
  // [0] function settleLoan()



/* Function "settleLoan" assigned keyword "external" to be called from other contracts 
 i.e "LoanUtilities.sol" via transactionstakes, it takes arguments [bytes calldata 
 _proofData, bytes32 _currentInterestBalance, address _lender] where, "_proofData" 
 variable of type "bytes" behaves as reference type variable and is stored in "calldata" to not be modified and meant to avoid copying, "_currentInterestBalance" variable and "_lender" variable of type address for lender address, use call function [msg.sender] to make sure it's not the loan dapp it, then process the loan settlement by passing attribute "_processLoanSettlement" for the "LoanUtilities.sol" with arguments "_proofData, loanVariables" , after that modify the "loanVariables" attributes like, loanSettlementDate, lastInterestPaymentDate,currentInterestBalance and lender, address _lender 
 */
 
  //Note: attributes "loanSettlementDate & lastInterestPaymentDate" time-stamped by block.timestamp
  
  
  function settleLoan(
    bytes calldata _proofData,
    bytes32 _currentInterestBalance,
    address _lender
  ) external {
    LoanUtilities.onlyLoanDapp(msg.sender, loanVariables.loanFactory);

    LoanUtilities._processLoanSettlement(_proofData, loanVariables);

    loanVariables.loanSettlementDate = block.timestamp;
    loanVariables.lastInterestPaymentDate = block.timestamp;
    loanVariables.currentInterestBalance = _currentInterestBalance;
    loanVariables.lender = _lender;
    lender = _lender;
  }


  // [1] function confidentialMint()



/* Function confidentialMint() assigned keyword "external" to be called from other contract "LoanUtilities" with the attribute "onlyLoanDapp" makes the check it's not the loan dapp by the call function "msg.sender" and call "loanVariables.loanFactory" attributes, and uses the call function "msg.sender== owner" to make sure only the owner calls it, also checks the proof is not equal to zero by assiging ".lenght" to the variable "_proofData", then it uses argument {(bytes memory _proofOutputs) = ace.mint(_proof, _proofData, msg.sender)} to mint by checking "_proofOutputs" aganist [_proof, _proofData, msg.sender] and extract the extract the tuble member "newTotal" from "_proofOutputs.get(0)" first argument and tuble member "mintedNotes" from "_proofOutputs.get(1)" second member, and finally the "noteHash" and "metadata" to be committed extracted out of "newTotal", after that emit the event "UpdateTotalMinted" with the identifiers "(noteHash, metadata)"    
*/


  function confidentialMint(uint24 _proof, bytes calldata _proofData) external {
    LoanUtilities.onlyLoanDapp(msg.sender, loanVariables.loanFactory);
    require(msg.sender == owner, "only owner can call the confidentialMint() method");
    require(_proofData.length != 0, "proof invalid");
    // overide this function to change the mint method to msg.sender
    (bytes memory _proofOutputs) = ace.mint(_proof, _proofData, msg.sender);

    (, bytes memory newTotal, ,) = _proofOutputs.get(0).extractProofOutput();

    (, bytes memory mintedNotes, ,) = _proofOutputs.get(1).extractProofOutput();

    (,
    bytes32 noteHash,
    bytes memory metadata) = newTotal.extractNote();

    logOutputNotes(mintedNotes);
    emit UpdateTotalMinted(noteHash, metadata);
  }


  // [2] function withdrawInterest()
  
  

/* Function withdrawInterest() with visiblity "public" costs more gas due to the fact it copies its arguments to memory " a necessity for its utility to withdraw Interest on the loan", it takes parameters "_proof1, _proof2 and __interestDurationToWithdraw" and checks it's arguments first: "(,bytes memory _proof1OutputNotes)" aganist [LoanUtilities._validateInterestProof] to validate _proof1, interestDurationToWithdraw and loanVariables and return "_proof1Output" and store it in memory to be passed as parameter for the function., Second: It utilize the second argument "require() function" to check "_interestDurationToWithdraw" with the addition of "lastInterestPaymentDate" is < the block.timestamp of the current time otherwise it emits to the user the message "withdraw is greater than accrued interest", for the Third: It utilize the contract "LoanUtilities.sol" at its attripute "_processInterestWithdrawal" for processing the withdrawal aganist the variables "_proof2, _proof1OutputNotes, loanVariables", Fourth: It calculate the "currentInterestBlance" for the user and assigned it to new variable "newCurrentInterestNoteHash", Fifth: It calculate the "lastInterestPaymentDate" for user by adding the "_interestDurationToWithdraw" and emits the LoanPayment state change for the user by the message 'INTEREST' Aadded to "lastInterestPaymentDate" 
*/ 

  function withdrawInterest(
    bytes memory _proof1,
    bytes memory _proof2,
    uint256 _interestDurationToWithdraw
  ) public {
    (,bytes memory _proof1OutputNotes) = LoanUtilities._validateInterestProof(_proof1, _interestDurationToWithdraw, loanVariables);

    require(_interestDurationToWithdraw.add(loanVariables.lastInterestPaymentDate) < block.timestamp, ' withdraw is greater than accrued interest');

    (bytes32 newCurrentInterestNoteHash) = LoanUtilities._processInterestWithdrawal(_proof2, _proof1OutputNotes, loanVariables);

    loanVariables.currentInterestBalance = newCurrentInterestNoteHash;
    loanVariables.lastInterestPaymentDate = loanVariables.lastInterestPaymentDate.add(_interestDurationToWithdraw);

    emit LoanPayment('INTEREST', loanVariables.lastInterestPaymentDate);

  }


  // [3] function adjustInterestBalance()
  
  
  
/* Function adjustInterestBalance() with visiblity "public" costs more gas due to the fact it copies its arguments to memory " a necessity for its utility to adjust Interest balance of the loan", Takes "_proofData" parameter as input, and got three arguments; First: it uses the call function[msg.sender] and the borrower variable to attest to the "LoanUtilities.sol" contract the ".onlyBorrower" attribute is fullfilled and only the sender is the borrower, Second: In order process adjustment for the intrest it require the attribute "_processAdjustInterest" for the contract "LoanUtilities.sol" is passed by to variables "_proofData, loanVariables" to the "newCurrentInterestBalance" and equal to and update finally the "currentInterestBalance" attribute for the loanVariables.
*/
  
  
  function adjustInterestBalance(bytes memory _proofData) public {

    LoanUtilities.onlyBorrower(msg.sender,borrower);

    (bytes32 newCurrentInterestBalance) = LoanUtilities._processAdjustInterest(_proofData, loanVariables);
    loanVariables.currentInterestBalance = newCurrentInterestBalance;
  }


  // [4] function repayLoan()
  
  
  
/* Function repayLoan() with visiblity "public" costs more gas due to the fact it copies its arguments variables updates to memory " a necessity for its utility to repay the loan", takes "_proof1 & _proof2" as input parameter inputs, and requires that the {loan has matured} loanSettlementDate added to duration is less than the current time (block.timestamp) otherwise it emits to user the message 'loan has not matured', then it process the loan repayment by passing the attribute "._processLoanRepayment" with the parameters "_proof2, _proof1OutputNotes and loanVariables" to the smart contract "LoanUtilities.sol", First: it uses the call function "msg.sender" to check that the sender is the only brrower, and calculating "remainingInterestDuration" aganist {"loanSettlementDate" added to duration of the loan "loanVariables.duration" subtracted from "lastInterestPaymentDate" of the loan}, and takes the value of "_proof1OutputNotes" as an identifier aganist a valid interest proof "_validateInterestProof" afetr checking the proof of the remaining duration "(_proof1, remainingInterestDuration, loanVariables)", Finally it emits to the EVM state that the loan is repaid.
*/

  
  function repayLoan(
    bytes memory _proof1,
    bytes memory _proof2
  ) public {
    LoanUtilities.onlyBorrower(msg.sender, borrower);

    uint256 remainingInterestDuration = loanVariables.loanSettlementDate.add(loanVariables.duration).sub(loanVariables.lastInterestPaymentDate);

    (,bytes memory _proof1OutputNotes) = LoanUtilities._validateInterestProof(_proof1, remainingInterestDuration, loanVariables);

    require(loanVariables.loanSettlementDate.add(loanVariables.duration) < block.timestamp, 'loan has not matured');


    LoanUtilities._processLoanRepayment(
      _proof2,
      _proof1OutputNotes,
      loanVariables
    );

    emit LoanRepaid();
  }



  // [5] function markLoanAsDefault()
  
  
  
/* Function marLoanAsDefault() with visiblity "public" costs more gas due to the fact it copies its arguments variables updates to memory " a necessity for its utility to mark the loan as defaulted", it requires that the ".lastInterestPaymentDate" attribute of the loanVariables added to the "_interestDurationToWithdraw" is lesser than the current time "< block.timestamp" otherwise it pop the message 'withdraw is greater than accrued interest', also checking the validity of the seconf argument that the "LoanUtilities.sol" attribute "._validateDefaultProofs" fulfill the parameters "_proof1, _proof2, _interestDurationToWithdraw, loanVariables" to emits the EVM state a value of function LoanDefault().
*/

  
  function markLoanAsDefault(bytes memory _proof1, bytes memory _proof2, uint256 _interestDurationToWithdraw) public {
    require(_interestDurationToWithdraw.add(loanVariables.lastInterestPaymentDate) < block.timestamp, 'withdraw is greater than accrued interest');
    LoanUtilities._validateDefaultProofs(_proof1, _proof2, _interestDurationToWithdraw, loanVariables);
    emit LoanDefault();
  }
}
