// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from 'forge-std/Test.sol';
import {SweepStocks} from '../src/SweepStocks.sol';
import {DeploySweepStocks} from '../script/DeploySweepStocks.s.sol';

contract SweepStocksTest is Test {
    SweepStocks public sweepStocks;

    address USER = makeAddr('user');
    uint constant STARTING_BALANCE = 10 ether;

    function setUp() public {
        vm.deal(USER, STARTING_BALANCE);
        DeploySweepStocks deploySweepStocks = new DeploySweepStocks();
        sweepStocks = deploySweepStocks.run();
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
        assertEq(sweepStocks.winner(), 0, 'Incorrect value');
    }

    function testMintFailWithoutEth() public {
        vm.prank(USER);
        vm.expectRevert();
        sweepStocks.mint(USER, 1, 1, '');
    }

    function testMint() public {
        // hoax(address(0), ETH_BALANCE); //Create sender with eth balance
        hoax(address(1), 1e18);
        sweepStocks.mint{value: 1e18}(address(1), 1, 10, '');
        assertEq(sweepStocks.balanceOf(address(1), 1), 10);
    }

    function testBuyToken() public {
        hoax(msg.sender, 1e18);
        sweepStocks.mint{value: 1e18}(msg.sender, 1, 10, '');
        console.log(sweepStocks.balanceOf(msg.sender, 1));
        sweepStocks.setTokenPrice(1, 1e17);
        sweepStocks.buyToken{value: 1e18}(1, 10, msg.sender);
    }
}
// }
