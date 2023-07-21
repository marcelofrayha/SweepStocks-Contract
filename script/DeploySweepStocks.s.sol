// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13 .0;

import {Script, console} from 'forge-std/Script.sol';
import {SweepStocks} from '../src/SweepStocks.sol';
import {HelperConfig} from './HelperConfig.s.sol';
import {LinkTokenInterface} from 'node_modules/@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

contract DeploySweepStocks is Script {
    function fundContract(address link, address contractAddress) public {
        if (block.chainid == 31337) {
            //local anvil chain
        }
    }

    function run() external returns (SweepStocks) {
        HelperConfig helperConfig = new HelperConfig();
        (, address token, , string memory league) = helperConfig
            .activeNetworkConfig();
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        SweepStocks sweepStocks = new SweepStocks(league);
        LinkTokenInterface(token).transfer(address(sweepStocks), 1e17);
        console.log(LinkTokenInterface(token).balanceOf(address(sweepStocks)));
        vm.stopBroadcast();
        return sweepStocks;
    }
}
