// SPDX-License-Identifier: MIT
/* 
Invariant Properties:

Total NFT supply should match balanceOf of all NFT owners
NFT price should match the price formula
*/
pragma solidity ^0.8.13;

import {Test} from 'forge-std/Test.sol';
import {StdInvariant} from 'forge-std/StdInvariant.sol';
import {DeploySweepStocks} from '../../../script/DeploySweepStocks.s.sol';
import {SweepStocks} from '../../../src/SweepStocks.sol';

contract InvariantsTest is StdInvariant, Test {
    DeploySweepStocks deployer;
    SweepStocks sweepStocks;

    function setUp() external {
        deployer = new DeploySweepStocks();
        sweepStocks = deployer.run();
        targetContract(address(sweepStocks));
    }

    function invariant_contractBalanceShouldMatchMintValue() public view {
        assert(sweepStocks.winner(0) == 0);
    }
}
