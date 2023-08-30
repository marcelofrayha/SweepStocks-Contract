// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13 .0;

import {Script, console} from 'forge-std/Script.sol';
import {SweepStocks} from '../src/SweepStocks.sol';
import {Factory} from '../src/ContractFactory.sol';
import {HelperConfig} from './HelperConfig.s.sol';
import {LinkTokenInterface} from 'node_modules/@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

error TransferFailed();

contract DeploySweepStocks is Script {
    // function fundContract(address link, address contractAddress) public {
    //     if (block.chainid == 31337) {
    //         //local anvil chain
    //     }
    // }

    function run() external returns (SweepStocks) {
        HelperConfig helperConfig = new HelperConfig();
        (, address token, , string memory league) = helperConfig
            .activeNetworkConfig();
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        Factory factory = new Factory(league);
        console.log(address(factory));

        SweepStocks sweepStocks = factory.createContract(0);
        sweepStocks.acceptOwnership();
        console.log(address(sweepStocks));
        bool success = LinkTokenInterface(token).transfer(
            address(sweepStocks),
            6e17
        );
        if (!success) revert TransferFailed();
        console.log(LinkTokenInterface(token).balanceOf(address(sweepStocks)));
        sweepStocks.registerAndPredictID();
        console.log(LinkTokenInterface(token).balanceOf(address(sweepStocks)));
        vm.stopBroadcast();
        return sweepStocks;
    }
}
