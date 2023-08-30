// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13 .0;

import './SweepStocks.sol';
import {ConfirmedOwner} from './ChainlinkConsumer.sol';

error notOwner();
error emptyList();

contract Factory is ConfirmedOwner {
    address[] public contractList;
    string public league;

    constructor(string memory _league) ConfirmedOwner(msg.sender) {
        league = _league;
    }

    function createContract() public onlyOwner returns (SweepStocks) {
        SweepStocks newInstance = new SweepStocks(league, msg.sender);
        contractList.push(address(newInstance));
        return newInstance;
    }

    function getLastContract() public view returns (address) {
        if (contractList.length == 0) revert emptyList();
        return contractList[contractList.length - 1];
    }
}
