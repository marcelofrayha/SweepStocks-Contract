// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

library OraclesMode {
    error EmptyArray();
    error NoModeFound();

    function calculateMode(
        uint8[] memory values,
        mapping(uint => uint) storage valueCounts
    ) external returns (uint8) {
        if (values.length == 0) revert EmptyArray();
        // Reset Counter
        for (uint i = 0; i < values.length; ) {
            valueCounts[values[i]] = 0;
            unchecked {
                i++;
            }
        }
        // Create a mapping to count the occurrences of each value
        // Initialize variables to track the mode
        uint8 modeValue;
        uint maxCount = 0;

        // Iterate through the array to count occurrences
        for (uint i = 0; i < values.length; ) {
            valueCounts[values[i]]++;

            // Update mode if a new maximum count is reached
            if (valueCounts[values[i]] > maxCount) {
                maxCount = valueCounts[values[i]];
                modeValue = values[i];
            }
            unchecked {
                i++;
            }
        }

        // Ensure that there is a mode (at least one value with a count > 0)
        if (maxCount == 0) revert NoModeFound();

        return modeValue;
    }

    function recordWinnerResponse(
        uint response,
        uint[] storage winnerResponses
    ) public {
        winnerResponses.push(response);
    }

    // Function to record oracle responses for winner2
    function recordWinner2Response(
        uint response,
        uint[] storage winner2Responses
    ) public {
        winner2Responses.push(response);
    }

    // Function to record oracle responses for winner3
    function recordWinner3Response(
        uint response,
        uint[] storage winner3Responses
    ) public {
        winner3Responses.push(response);
    }
}
