// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

library BuyTokenChecks {
    error NotActive();
    error NotEnoughValue();
    error CallFailed();

    function buyToken(
        uint id,
        uint amount,
        address nftOwner,
        uint8[3] calldata winner,
        address _owner,
        mapping(uint => mapping(address => uint)) storage transferPrice
    ) external {
        if (winner[0] != 0) {
            revert NotActive();
        }
        if (
            msg.value != transferPrice[id][nftOwner] * amount &&
            msg.value != (transferPrice[id][nftOwner] * amount) + 1 &&
            msg.value != (transferPrice[id][nftOwner] * amount) - 1
        ) {
            revert NotEnoughValue();
        }
        uint earnings = ((amount * transferPrice[id][nftOwner] * 999) / 1000);
        payable(nftOwner).transfer(earnings);
        payable(_owner).transfer(
            ((transferPrice[id][nftOwner] * amount) / 1000)
        );

        // emit TokenBought(
        //     id,
        //     nftOwner,
        //     msg.sender,
        //     amount,
        //     (earnings / amount),
        //     block.timestamp
        // );
    }
}
