// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13 .0;

import './SweepStocks.sol';
import {ConfirmedOwner} from './ChainlinkConsumer.sol';

error notOwner();
error emptyList();

contract Factory is ConfirmedOwner {
    address[] private contractList;
    string private league;

    /**
     * @dev Constructor function to initialize the APIConsumer contract with a league name.
     * @param _league The name of the football league associated with this contract.
     */
    constructor(string memory _league) ConfirmedOwner(msg.sender) {
        league = _league;
    }

    /**
     * @dev Create a new SweepStocks contract instance and add it to the contract list.
     * Only the owner of the APIConsumer contract can create new instances.
     * @param duration The duration of the SweepStocks contract.
     * @return newInstance The address of the newly created SweepStocks instance.
     */
    function createContract(
        uint duration
    ) external onlyOwner returns (SweepStocks) {
        SweepStocks newInstance = new SweepStocks(league, msg.sender, duration);
        contractList.push(address(newInstance));
        return newInstance;
    }

    /**
     * @dev Get the address of the last created SweepStocks contract.
     * @return The address of the last created SweepStocks contract.
     */
    function getLastContract() external view returns (address) {
        if (contractList.length == 0) revert emptyList();
        return contractList[contractList.length - 1];
    }
}
