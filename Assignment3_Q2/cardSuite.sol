
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

// Import verifier.sol with the new validation key //

import "./verifier.sol";

// Inherit Verifier contract as we might not need Pairing contract //

contract cardSuite is Verifier {

    function play(
    
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
        
    ) public view returns (bool) {
        require(
            verifyProof(a, b, c, input),
            "The cards needs to have the same suite!"
        );

        return true;
    }
}
