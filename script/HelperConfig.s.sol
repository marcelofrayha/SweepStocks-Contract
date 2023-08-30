// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13 .0;

import {Script} from 'forge-std/Script.sol';
import {LinkToken} from '../test/mocks/LinkToken.sol';

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 80001) activeNetworkConfig = getMumbaiConfig();
        else if (block.chainid == 1101)
            activeNetworkConfig = getPolygonZKConfig();
        else if (block.chainid == 137) activeNetworkConfig = getPolygonConfig();
        else activeNetworkConfig = getAnvilConfig();
    }

    struct NetworkConfig {
        address oracle;
        address token;
        string jobId;
        string league;
    }

    function getPolygonZKConfig() public pure returns (NetworkConfig memory) {
        // NetworkConfig memory polygonzkConfig = NetworkConfig();
        // oracle: 0x7ca7215c6B8013f249A195cc107F97c4e623e5F5,
        // token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
        // jobId: "0bf991b9f60b4f72964c1e6afc34f099",
        // league: "brazil"
        // return polygonzkConfig;
    }

    function getPolygonConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory polygonConfig = NetworkConfig({
            oracle: 0x7ca7215c6B8013f249A195cc107F97c4e623e5F5,
            token: 0xb0897686c545045aFc77CF20eC7A532E3120E0F1,
            jobId: '0bf991b9f60b4f72964c1e6afc34f099',
            league: 'france'
        });
        return polygonConfig;
    }

    function getMumbaiConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mumbaiConfig = NetworkConfig({
            oracle: 0x7ca7215c6B8013f249A195cc107F97c4e623e5F5,
            token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            jobId: '0bf991b9f60b4f72964c1e6afc34f099',
            league: 'portugal'
        });
        return mumbaiConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        LinkToken link = new LinkToken();

        NetworkConfig memory anvilConfig = NetworkConfig({
            oracle: 0x7ca7215c6B8013f249A195cc107F97c4e623e5F5,
            token: address(link),
            jobId: '0bf991b9f60b4f72964c1e6afc34f099',
            league: 'england'
        });
        return anvilConfig;
    }
}

// 0xb4a530D50E5d83AB6c401350F884E285f5c1D810 england factory
