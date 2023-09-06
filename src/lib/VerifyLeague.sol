// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

error InvalidLeague(string _league);

library VerifyLeague {
    function validLeague(string calldata _league) external pure {
        if (
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('germany')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('brazil')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('spain')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('italy')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('portugal')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('england')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('argentina')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('france'))
        ) {
            revert InvalidLeague(_league);
        }
    }

    function calculateLeagueSize(
        string calldata league
    ) external pure returns (uint leagueSize) {
        if (
            keccak256(abi.encodePacked(league)) ==
            keccak256(abi.encodePacked('germany')) ||
            keccak256(abi.encodePacked(league)) ==
            keccak256(abi.encodePacked('portugal'))
        ) return 18;
        else if (
            keccak256(abi.encodePacked(league)) ==
            keccak256(abi.encodePacked('argentina'))
        ) return 28;
        else return 20;
    }

    function timeLeft(
        uint i_creationTime,
        uint i_duration
    ) external view returns (uint) {
        int time = (int(i_creationTime) +
            (1 + int(i_duration)) *
            1 days -
            int(block.timestamp));
        return time > 0 ? uint(time) / 86400 : 0;
    }
}
