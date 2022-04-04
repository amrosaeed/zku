import { add } from '/ThreeFields.ts';
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
