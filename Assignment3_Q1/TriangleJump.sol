// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./verifier.sol";

contract TriangleJump {
    // Some generic state variable
    uint public num;

    Verifier private verifier;

    constructor(address _verifierAddress) {
        verifier = Verifier(_verifierAddress);
    }

    // Just a generic function to represent some state update
    function updateSomeState(uint _num) public {
        num = _num;
    }

    function executeTriangleMove(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input) 
        public 
    {
        require(verifier.verifyProof(a, b, c, input),
        "The Triangle Jump is invalid.");

        // Execute some state update after verifying the proof (just an example)
        updateSomeState(a[0]);
    }
}
