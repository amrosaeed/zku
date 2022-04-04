import {
  Field,
  prop,
  PublicKey,
  CircuitValue,
  Signature,
  UInt64,
  UInt32,
  KeyedAccumulatorFactory,
  ProofWithInput,
  proofSystem,
  branch,
  MerkleStack,
  shutdown,
} from 'snarkyjs';

const AccountDbDepth: number = 32;
const AccountDb = KeyedAccumulatorFactory<PublicKey, RollupAccount>(
  AccountDbDepth
);
type AccountDb = InstanceType<typeof AccountDb>;

class RollupAccount extends CircuitValue {
  @prop balance: UInt64;
  @prop nonce: UInt32;
  @prop publicKey: PublicKey;

  constructor(balance: UInt64, nonce: UInt32, publicKey: PublicKey) {
    super();
    this.balance = balance;
    this.nonce = nonce;
    this.publicKey = publicKey;
  }
}

class RollupTransaction extends CircuitValue {
  @prop amount: UInt64;
  @prop nonce: UInt32;
  @prop sender: PublicKey;
  @prop receiver: PublicKey;

  constructor(
    amount: UInt64,
    nonce: UInt32,
    sender: PublicKey,
    receiver: PublicKey
  ) {
    super();
    this.amount = amount;
    this.nonce = nonce;
    this.sender = sender;
    this.receiver = receiver;
  }
}

class RollupDeposit extends CircuitValue {
  @prop publicKey: PublicKey;
  @prop amount: UInt64;
  constructor(publicKey: PublicKey, amount: UInt64) {
    super();
    this.publicKey = publicKey;
    this.amount = amount;
  }
}

class RollupState extends CircuitValue {
  @prop pendingDepositsCommitment: Field;
  @prop accountDbCommitment: Field;
  constructor(p: Field, c: Field) {
    super();
    this.pendingDepositsCommitment = p;
    this.accountDbCommitment = c;
  }
}

class RollupStateTransition extends CircuitValue {
  @prop source: RollupState;
  @prop target: RollupState;
  constructor(source: RollupState, target: RollupState) {
    super();
    this.source = source;
    this.target = target;
  }
}


// Q3 Recursive SNARK’s



       // [Bonus] In bonus.ts we can see the implementation of zkRollup with the use of recursion. 
       // Explain 87-148 lines of code (comment the code inline).



// a recursive proof system is kind of like an "enum"

/// Merge 1st Rollup proof result into 2nd Rollup proof "where, recursion took place" and returns a proof validating 
/// state transition.
/// Javascript uses run-time statistics that indicate where branch correlation occurs
@proofSystem
class RollupProof extends ProofWithInput<RollupStateTransition> {
  /// Fetch the account state from Db & instantiate a rollup deposit.
  @branch static processDeposit(
    pending: MerkleStack<RollupDeposit>,
    accountDb: AccountDb
  ): RollupProof {
    /// Get the state of the rollup.
    let before = new RollupState(pending.commitment, accountDb.commitment());
    /// From the mempool Db use "(deposit.publicKey)" to Pop the last deposit.
    let deposit = pending.pop();
    /// Check the Db account/pubkey being deposited doesn't exist otherwise message false.
    let [{ isSome }, mem] = accountDb.get(deposit.publicKey);
    isSome.assertEquals(false);

    /// Initialise the account with zero balance and nonce.
    let account = new RollupAccount(
      UInt64.zero,
      UInt32.zero,
      deposit.publicKey
    );
    accountDb.set(mem, account);
   /// Use "new RollupStateTransition" to return the resulting state of the rollup before & after.
    let after = new RollupState(pending.commitment, accountDb.commitment());

   /// Return a proof to validate the Rollup state transition.
    return new RollupProof(new RollupStateTransition(before, after));
  }

  /// Javascript uses run-time statistics that indicate where branch correlation occurs
  @branch static transaction(
    t: RollupTransaction,
    s: Signature,
    pending: MerkleStack<RollupDeposit>,
    accountDb: AccountDb
  ): RollupProof {
  
  /// Verify that the provided signature was signed by the sender for the specified transaction.
    s.verify(t.sender, t.toFields()).assertEquals(true);
    
  /// Let the last state of the rollup be the new one.
    let stateBefore = new RollupState(
      pending.commitment,
      accountDb.commitment()
    );

  /// Match the sender's account, use the nonce to validate it existence of that specified transaction
    let [senderAccount, senderPos] = accountDb.get(t.sender);
    senderAccount.isSome.assertEquals(true);
    senderAccount.value.nonce.assertEquals(t.nonce);

  /// Check senderAccount value and subtract the sender's sent amount from their balance 
    senderAccount.value.balance = senderAccount.value.balance.sub(t.amount);
  /// Increment sender's account nonce 
    senderAccount.value.nonce = senderAccount.value.nonce.add(1);

  /// Update accountDb with changes made to the sender's account.
    accountDb.set(senderPos, senderAccount.value);

  /// Update accountDb with changes made to the reciever's account.
    let [receiverAccount, receiverPos] = accountDb.get(t.receiver);
    receiverAccount.value.balance = receiverAccount.value.balance.add(t.amount);
    accountDb.set(receiverPos, receiverAccount.value);

  /// Get the resulting state of the rollup.
    let stateAfter = new RollupState(
      pending.commitment,
      accountDb.commitment()
    );
  /// Return a proof to validate the Rollup state transition.
    return new RollupProof(new RollupStateTransition(stateBefore, stateAfter));
  }

  /// Merge 1st Rollup proof result into 2nd Rollup proof "where, recursion took place" and returns a proof validating 
  /// the Rollup state transition.
  @branch static merge(p1: RollupProof, p2: RollupProof): RollupProof {
    p1.publicInput.target.assertEquals(p2.publicInput.source);
    return new RollupProof(
      new RollupStateTransition(p1.publicInput.source, p2.publicInput.target)
    );
  }
}

shutdown();
