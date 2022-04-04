// Q3 Recursive SNARK’s

            /* [Infrastructure Track only] Clone github repo. Go through the snapps from the src folder and try to understand the code. Create a new snapp that will have 3 fields. Write an update function which will update all 3 fields. Write a unit test for your snapp.*/

import {
    Field,
    PrivateKey,
    PublicKey,
    SmartContract,
    state,
    State,
    method,
    UInt64,
    Mina,
    Party,
    isReady,
    shutdown,
  } from 'snarkyjs';

  class ThreeFields extends SmartContract {
    @state(Field) x: State<Field>;
    @state(Field) y: State<Field>;
    @state(Field) z: State<Field>;

    constructor(
    initialBalance: UInt64, 
    address: PublicKey, 
    x: Field, 
    y: Field, 
    z: Field
    ) {
        super(address);
        
        this.balance.addInPlace(initialBalance);
        
        this.x = State.init(x);
        this.y = State.init(y);
        this.z = State.init(z);
      }

    @method async update(updated: Field) {
        const x = await this.x.get();
        const y = await this.y.get();
        const z = await this.z.get();
        const num = new Field(18);

        num.assertEquals(updated);

        this.x.set(updated);
        this.y.set(updated);
        this.z.set(updated);

      }
}

  export async function run(){
        await isReady;

        const Local = Mina.LocalBlockchain();
        Mina.setActiveInstance(Local);
        const account1 = Local.testAccounts[0].privateKey;
        const account2 = Local.testAccounts[1].privateKey;
      
        const snappPrivkey = PrivateKey.random();
        const snappPubkey = snappPrivkey.toPublicKey();

        let snappInstance: ThreeFields;
        
        const initX = new Field(6);
        const initY = new Field(6);
        const initZ = new Field(6);


        // Deploys the snapp
        await Mina.transaction(account1, async () => {
        // account2 sends 1000000000 to the new snapp account
        const amount = UInt64.fromNumber(1000000000);
        const p = await Party.createSigned(account2);
        p.balance.subInPlace(amount);

        snappInstance = new ThreeFields(
        amount, 
        snappPubkey, 
        initX, 
        initY, 
        initZ
        );
    })
        .send()
        .wait();

        const InsertedValue = await Mina.getAccount(snappPubkey);

        console.log("ThreeFields");
        console.log(
           "Inserted Value: ",
           [
            InsertedValue.snapp.appState[0].toString(),
            InsertedValue.snapp.appState[1].toString(),
            InsertedValue.snapp.appState[2].toString(),
           ].join(", ")
         );

          // Update the snapp
        await Mina.transaction(account1, async () => {
            await snappInstance.update(new Field(18));
        })
            .send()
            .wait();

         // second update attempt
        await Mina.transaction(account1, async () => {
            // Fails, because the provided value is wrong.
            await snappInstance.update(new Field(20));
            })
            .send()
            .wait()
            .catch((e) => console.log('second update attempt failed'));
        
            const a = await Mina.getAccount(snappPubkey);
        
            console.log('final state value of x', a.snapp.appState[0].toString());
            console.log('final state value of y', a.snapp.appState[1].toString());
            console.log('final state value of z', a.snapp.appState[2].toString());

}

run();

shutdown();
