/* Q.2 Aztec

AZTEC protocol utilizes a set of zero-knowledge proofs to define a confidential transaction protocol, to shield both native assets and assets that conform with certain standards (e.g. ERC20) on a Turing-complete general-purpose computation.

     Q2.2:
     [Infrastructure Track Only] Using the loan application as a reference point, briefly explain how AZTEC can be used to create a private loan application on the blockchain highlighting the benefits and challenges. In the Loan Application, explain the Loan.sol and LoanDapp.sol file (comment inline) */

// Define solidity version
pragma solidity >= 0.5.0 <0.7.0;
// Import required libraries

// An interface defining the ZkAsset standard.
import "@aztec/protocol/contracts/interfaces/IAZTEC.sol";
// A utility library that extracts user-readable information from AZTEC proof outputs.
import "@aztec/protocol/contracts/libs/NoteUtils.sol";
import "@aztec/protocol/contracts/ERC1724/ZkAsset.sol";
import "./ZKERC20/ZKERC20.sol";
// Import loan implementation
import "./Loan.sol";

// Inherit IAZTEC contract as Interface for LoanDapp contract.
contract LoanDapp is IAZTEC {
// Use NoteUtils typing bytes variables.
  using NoteUtils for bytes;

// Declare an event "SettlementCurrencyAdded", it stores the arguments passed 
// "uint id, address settlementAddress" in transaction logs.
  event SettlementCurrencyAdded(
    uint id,
    address settlementAddress
  );
// Declare an event "LoanApprovedForSettlement", it stores the arguments passed 
// "address loanId" in transaction logs.
  event LoanApprovedForSettlement(
    address loanId
  );
// Declare an event "LoanCreated", it stores the arguments passed "address id, address borrower, bytes32 notional, 
// string borrowerPublicKey, uint256[] loanVariables, uint createdAt" in transaction logs.
  event LoanCreated(
    address id,
    address borrower,
    bytes32 notional,
    string borrowerPublicKey,
    uint256[] loanVariables,
    uint createdAt
  );
// Declare an event "ViewRequestCreated", it stores the arguments passed 
// "loanId, lender, lenderPublicKey" in transaction logs.
  event ViewRequestCreated(
    address loanId,
    address lender,
    string lenderPublicKey
  );
// Declare an event "ViewRequestApproved", it stores the arguments passed 
// "accessId, loanId, user, sharedSecret" in transaction logs.
  event ViewRequestApproved(
    uint accessId,
    address loanId,
    address user,
    string sharedSecret
  );
// Declare an event "NoteAccessApproved", it stores the arguments passed 
// "accessId, note, user, sharedSecret" in transaction logs.
  event NoteAccessApproved(
    uint accessId,
    bytes32 note,
    address user,
    string sharedSecret
  );
// Declaring variable "owner" of type "address" and assigning it's value to 
// the return of call back function "mes.sender".
  address owner = msg.sender;
  address aceAddress;
// Declaring variable "loans" of type "address" to store a list of loans addresses.
  address[] public loans;
  mapping(uint => address) public settlementCurrencies;
// The various proofs utilized by the AZTEC protocol.
  uint24 MINT_PRO0F = 66049;
  uint24 BILATERAL_SWAP_PROOF = 65794;
// Modifier "onlyOwner()" for function addSettlementCurrency(), that requires the return value of call back function 
// "msg.sender" to assign only the owner to execute.
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

// Modifier "onlyBorrower()" for function approveViewRequest(), that requires the return value of call back function 
// "msg.sender" to assign only the Borrower to execute by mapping the value of loan contract to loan address.
  modifier onlyBorrower(address _loanAddress) {
    Loan loanContract = Loan(_loanAddress);
    require(msg.sender == loanContract.borrower());
    _;
  }

  constructor(address _aceAddress) public {
    aceAddress = _aceAddress;
  }
// Function _getCurrencyContract() takes "_settlementCurrencyId" as an input parameter
// and checks if the _settlementCurrencyId exist in the settlementCurrencies mapping
// and returns the address, otherwise it pop message 'Settlement Currency is not defined'.
  function _getCurrencyContract(uint _settlementCurrencyId) internal view returns (address) {
    require(settlementCurrencies[_settlementCurrencyId] != address(0), 'Settlement Currency is not defined');
    return settlementCurrencies[_settlementCurrencyId];
  }
// Function _generateAccessId() takes "bytes32 _note, address _user" as input parameters
// and returns the hash of the input parameters of type uint
  function _generateAccessId(bytes32 _note, address _user) internal pure returns (uint) {
    return uint(keccak256(abi.encodePacked(_note, _user)));
  }
// Function _approvedNoteAccess() takes "_note, _userAddress, _sharedSecret" as input parameters 
// and check the argument that the _generatedAccessId with both "_note & _userAddress" is assigned to accessId 
// and emits the the NoteAccess Approved with the values [accessId, _note, _userAddree and _sharedSecret].
  function _approveNoteAccess(
    bytes32 _note,
    address _userAddress,
    string memory _sharedSecret
  ) internal {
    uint accessId = _generateAccessId(_note, _userAddress);
    emit NoteAccessApproved(
      accessId,
      _note,
      _userAddress,
      _sharedSecret
    );
  }

// Function _createLoan() with input parameter as [bytes32 _notional, uint256[] memory _loanVariables, 
// bytes memory _proofData] sets a new loan to the sender with the required loan currency according variables 
// of the loan and push the new loan address to sender after checking MINT_PROOF & _proofData.
// Note: the "_" at _createLoan() function It returns the flow of execution for function/contract privacy.
  function _createLoan(
    bytes32 _notional,
    uint256[] memory _loanVariables,
    bytes memory _proofData
  ) private returns (address) {
    address loanCurrency = _getCurrencyContract(_loanVariables[3]);

    Loan newLoan = new Loan(
      _notional,
      _loanVariables,
      msg.sender,
      aceAddress,
      loanCurrency
    );

    loans.push(address(newLoan));
    Loan loanContract = Loan(address(newLoan));

    loanContract.setProofs(1, uint256(-1));
    // The various proofs utilized by the AZTEC protocol.
    loanContract.confidentialMint(MINT_PROOF, bytes(_proofData));
    // Returns the loan to value returned from "msg.sender" callback function.
    return address(newLoan);
  }
// Function  addSettlementCurrency() restricted by onlyOwner() modifier to assign him rights to choose
// loan's currency of settelment and emits it.
  function addSettlementCurrency(uint _id, address _address) external onlyOwner {
    settlementCurrencies[_id] = _address;
    emit SettlementCurrencyAdded(_id, _address);
  }

  function createLoan(
    bytes32 _notional,
    string calldata _viewingKey,
    string calldata _borrowerPublicKey,
    uint256[] calldata _loanVariables,
    // [0] interestRate
    // [1] interestPeriod
    // [2] loanDuration
    // [3] settlementCurrencyId
    bytes calldata _proofData
  ) external {
    address loanId = _createLoan(
      _notional,
      _loanVariables,
      _proofData
    );

    emit LoanCreated(
      loanId,
      msg.sender,
      _notional,
      _borrowerPublicKey,
      _loanVariables,
      block.timestamp
    );

    _approveNoteAccess(
      _notional,
      msg.sender,
      _viewingKey
    );
  }
// Function  approveLoanNotional() rwith public visibility to approve loan notion with loan ID to
// soecific loan contract considering confidentiality of loan approval
// emits loan approval state.
  function approveLoanNotional(
    bytes32 _noteHash,
    bytes memory _signature,
    address _loanId
  ) public {
    Loan loanContract = Loan(_loanId);
    loanContract.confidentialApprove(_noteHash, _loanId, true, _signature);
    emit LoanApprovedForSettlement(_loanId);
  }
// Function submitViewRequest() takes the lender public key as an input and emits view request
// of the loan ID with the arguments of both public key and value of "msg.sender" callback.
  function submitViewRequest(address _loanId, string calldata _lenderPublicKey) external {
    emit ViewRequestCreated(
      _loanId,
      msg.sender,
      _lenderPublicKey
    );
  }
// Function approveViewRequest() takes the [_loanId, _lender, _notionalNote & _sharedsecret; 
// while preserving the execution fallback to function] with modifier onlyOwner()' input "_loanId"
// and emits that the request approved with the parameters [accessId, _loanId, _lender, _sharedSecret] 

// Note: i dont know security measures taken of emitting "_sharedSecret" as an argument for an external function.
  function approveViewRequest(
    address _loanId,
    address _lender,
    bytes32 _notionalNote,
    string calldata _sharedSecret
  ) external onlyBorrower(_loanId) {
    uint accessId = _generateAccessId(_notionalNote, _lender);

    emit ViewRequestApproved(
      accessId,
      _loanId,
      _lender,
      _sharedSecret
    );
  }
// Emitting all the succefull settelments for indexed addresses.
  event SettlementSuccesfull(
    address indexed from,
    address indexed to,
    address loanId,
    uint256 timestamp
  );
// A struct LoanPayment for building a type structure of types (Indexed addresses and notional of bytes type).
  struct LoanPayment {
    address from;
    address to;
    bytes notional;
  }
// Mapping for loan payment addresses.
  mapping(uint => mapping(uint => LoanPayment)) public loanPayments;
// Function settleInitialBalance() to settle the initial balance of the user
// and emit the settelment success at certain time "block.timestamp) after checking both the loan contract "settleloan"  
// attribute & the "borrower" of the loan attribute.
  function settleInitialBalance(
    address _loanId,
    bytes calldata _proofData,
    bytes32 _currentInterestBalance
  ) external {
    Loan loanContract = Loan(_loanId);
    loanContract.settleLoan(_proofData, _currentInterestBalance, msg.sender);
    emit SettlementSuccesfull(
      msg.sender,
      loanContract.borrower(),
      _loanId,
      block.timestamp
    );
  }
// Obviously for approving the Note, after checking the "shardsecret byte length)
  function approveNoteAccess(
    bytes32 _note,
    string calldata _viewingKey,
    string calldata _sharedSecret,
    address _sharedWith
  ) external {
    if (bytes(_viewingKey).length != 0) {
      _approveNoteAccess(
        _note,
        msg.sender,
        _viewingKey
      );
    }

    if (bytes(_sharedSecret).length != 0) {
      _approveNoteAccess(
        _note,
        _sharedWith,
        _sharedSecret
      );
    }
  }
}
