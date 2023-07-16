// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13 .0;

import {Script} from "forge-std/Script.sol";
import {SweepStocks} from "../src/SweepStocks.sol";

contract DeploySweepStocks is Script {
    function run() external returns (SweepStocks) {
        vm.startBroadcast();
        SweepStocks sweepStocks = new SweepStocks("brazil");
        vm.stopBroadcast();
        return sweepStocks;
    }
}
