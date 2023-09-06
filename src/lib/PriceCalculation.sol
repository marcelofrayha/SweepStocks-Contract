// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

import {PriceDetails} from './PriceDetails.sol';

library PriceCalculation {
    function calculateAllPrices(
        mapping(uint => address[]) storage tokenOwners,
        mapping(uint => mapping(address => uint)) storage transferPrice,
        uint size
    ) external returns (PriceDetails[] memory) {
        PriceDetails[] memory priceDetails = new PriceDetails[](size);
        for (uint i = 1; i <= size; ) {
            address[] memory ownersList = tokenOwners[i];
            uint[] memory prices = new uint[](ownersList.length);
            for (uint j = 0; j < ownersList.length; ) {
                if (transferPrice[i][ownersList[j]] == 0) {
                    transferPrice[i][ownersList[j]] = 100000000 ether;
                }
                prices[j] = transferPrice[i][ownersList[j]];
                unchecked {
                    ++j;
                }
            }
            priceDetails[i - 1] = PriceDetails(i, ownersList, prices);
            unchecked {
                i++;
            }
        }
        return priceDetails;
    }

    function initialMintValue(
        uint size,
        mapping(uint => uint) storage mintPrice,
        uint initialValue
    ) external {
        for (uint i = 0; i < size; ) {
            mintPrice[i + 1] = initialValue;
            unchecked {
                i++;
            }
        }
    }

    function createMintPriceList(
        uint size,
        mapping(uint => uint) storage mintPrice
    ) external view returns (uint[] memory _mintPriceList) {
        uint[] memory mintPriceList = new uint[](size);
        for (uint i = 0; i < size; ) {
            mintPriceList[i] = mintPrice[i + 1];
            unchecked {
                i++;
            }
        }
        return mintPriceList;
    }
}
