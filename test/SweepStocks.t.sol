// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from 'forge-std/Test.sol';
import {StdInvariant} from 'forge-std/StdInvariant.sol';
import {SweepStocks} from '../src/SweepStocks.sol';
import {DeploySweepStocks} from '../script/DeploySweepStocks.s.sol';

contract SweepStocksTest is StdInvariant, Test {
    SweepStocks public sweepStocks;

    address USER = makeAddr('user');
    uint constant STARTING_BALANCE = 10 ether;

    function setUp() public {
        vm.deal(USER, STARTING_BALANCE);
        DeploySweepStocks deploySweepStocks = new DeploySweepStocks();
        sweepStocks = deploySweepStocks.run();
        targetContract(address(sweepStocks));
    }

    // Statefull fuzz testing
    function invariant_testWinnerIsZero() public view {
        assert(sweepStocks.winner(0) == 0);
    }

    // function testOwner() public {
    //     vm.prank(USER);

    //     address owner = sweepStocks.owner();
    //     console.log(owner);
    //     assertEq(owner, USER);
    // }

    function testWinnerIsZero() public {
        // Assert that the token was minted and exists
        // assertTrue(true, "Token does not exist");
        // Assert that the token owner is the caller of the mint function
        assertEq(sweepStocks.winner(0), 0, 'Incorrect value');
    }

    function testMintFailWithoutEth() public {
        vm.prank(USER);
        vm.expectRevert();
        sweepStocks.mint(USER, 1, 1, '');
    }

    function testMint() public {
        // hoax(address(0), ETH_BALANCE); //Create sender with eth balance
        vm.prank(USER);
        sweepStocks.mint{value: 1e18}(USER, 1, 10, '');
        assertEq(sweepStocks.balanceOf(USER, 1), 10);
    }

    function testBuyToken() public {
        vm.startPrank(USER);
        sweepStocks.mint{value: 1e18}(USER, 1, 10, '');
        sweepStocks.setTokenPrice(1, 1e17);
        sweepStocks.buyToken{value: 1e18}(1, 10, USER);
        vm.stopPrank();
    }
}
// }
