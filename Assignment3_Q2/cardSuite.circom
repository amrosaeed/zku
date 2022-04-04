
pragma circom 2.0.0;

    /*Import "mimcsponge" library for hashing & "gates" library for comparing suites.*/

include "./circomlib/circuits/mimcsponge.circom";
include "./circomlib/circuits/gates.circom";

    /*This circuit template Equal_Suites() compares Suite1 & Suite2.*/

template Equal_Suites() {
    
    /* Declare Input & Output signals for both cards.*/
    
    signal input Suite1;
    signal input Number1;
    signal input Nullifier1;
    
    signal input Suite2;
    signal input Number2;
    signal input Nullifier2;

    signal output Commitment1;
    signal output Commitment2;

    /* Verify the commitment of card1 (Suite, Number and Nullifier).*/
    
    component card1 = CommitCard();
    card1.Suite <== Suite1;
    card1.Number <== Number1;
    card1.Nullifier <== Nullifier1;
    card1.Commitment ==> Commitment1;

    /* Verify the commitment of card2 (Suite, Number and Nullifier).*/
    
    component card2 = CommitCard();
    card2.Suite <== Suite2;
    card2.Number <== Number2;
    card2.Nullifier <== Nullifier2;
    card2.Commitment ==> Commitment2;

    /* Use MultiAND(n) template from "gates" library to compare Suites.*/ 
    
    component multi_and_gate = MultiAND(2);
    
    multi_and_gate.in[0] <== Suite1;
    multi_and_gate.in[1] <== Suite2;
}

     /*This circuit template CommitCard() Assigns Commitments to combination of Suites, Number and Nullifiers.*/

template CommitCard() {
    
    signal input Suite;
    signal input Number;
    signal input Nullifier;
    
    
    signal output Commitment;

    /* Use template MiMCSponge(nInputs, nRounds, nOutputs) to hash (Suite, Number and NUllifier).*/
    
    component mimc = MiMCSponge(3, 220, 1);
    mimc.ins[0] <== Suite;    
    mimc.ins[1] <== Number;
    mimc.ins[2] <== Nullifier;
    mimc.k <== 0;
    
    /* Commit output of MIMC hash.*/ 
    
    Commitment <== mimc.outs[0];
}

component main = Equal_Suites();

