// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13 .0;

import {Script} from "forge-std/Script.sol";
import {SweepStocks} from "../src/SweepStocks.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySweepStocks is Script {
    function run() external returns (SweepStocks) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , string memory league) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        SweepStocks sweepStocks = new SweepStocks(league);
        vm.stopBroadcast();
        return sweepStocks;
    }
}
