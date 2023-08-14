// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SigmoidalFunction {
    uint256 private constant L = 130 ether;
    uint256 private constant k = 1;
    uint256 private constant x0 = 4333333333333 wei;
    uint256 private constant tableSize = 1000;

    uint256[1000] public sigmoidalValues;

    constructor() {
        run();
    }

    function run() private {
        for (uint256 i = 0; i < tableSize; i++) {
            uint256 amount = i * 100000 wei; // Adjust the increment as needed
            int256 expValue = int256(k * (amount - x0)) / int256(1 ether);
            int256 sigmoidalValue = int256(L) /
                (int256(1 ether) + (expValue * expValue) / 2);

            sigmoidalValues[i] = sigmoidalValue < 0
                ? 0
                : uint256(sigmoidalValue);
        }
    }

    // Function to get the sigmoidal value for a specific input
    function getSigmoidalValue(uint256 amount) public view returns (uint256) {
        uint256 index = amount / 100000 wei; // Adjust the increment as needed
        if (index < tableSize) {
            return sigmoidalValues[index];
        } else {
            return 0; // Return 0 for out-of-range inputs
        }
    }
}
