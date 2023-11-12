// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1155} from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import {ERC1155Supply} from '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import {APIConsumer, ConfirmedOwner} from './ChainlinkConsumer.sol';
import {PriceCalculation} from './lib/PriceCalculation.sol';
import {PriceDetails} from './lib/PriceDetails.sol';
import {VerifyLeague} from './lib/VerifyLeague.sol';
import {BuyTokenChecks} from './lib/BuyTokenChecks.sol';

error NotEnoughValue();
error NotActive();
error InvalidLeague();
error NotOwner();
error MintCap();
error BuyCap();
// error NFTReachedCap();
error CallFailed();
error InvalidId();

/// @title SweepStocks - A sweepstake game
/// @author Marcelo Frayha
/// @notice This contracts allows you to bet on a team from a football league and also negotiate your bets.
/// @dev This contract only works with oracles specified in ChainlinkConsumer.sol
/// @custom:experimental This is an experimental contract.
/// @custom:security-contact marcelofrayha@gmail.com
contract SweepStocks is ERC1155, ERC1155Supply, ConfirmedOwner, APIConsumer {
    using PriceCalculation for *;
    using VerifyLeague for *;
    using BuyTokenChecks for *;

    uint private immutable i_leagueSize;
    address private constant paperAddress =
        0x1d847dE548F15F19C67eebb13c918d4163Ce6ADE;
    uint private constant c_initialValue = 1 ether / 100;
    uint[3] public payout;
    // uint[3] public supply;
    bool private payoutDefined = false;
    mapping(uint => address[]) public tokenOwners;
    // Price to create a new NFT, this is handled by the contract
    mapping(uint => uint) public mintPrice;
    // Price set by the owner of a NFT
    mapping(uint => mapping(address => uint)) public transferPrice;

    PriceDetails[] private priceDetails;

    // event TokenPriceSet(uint indexed id, address indexed by, uint amount);
    // event TokenBought(
    //     uint indexed id,
    //     address from,
    //     address by,
    //     uint amount,
    //     uint indexed value,
    //     uint indexed time
    // );

    // event WinnerPaid(address indexed owner, uint indexed amount);
    /**
     * @dev Constructor function to initialize the SweepStocks contract.
     * @param _league The name of the football league country associated with this contract.
     * @param _owner The initial owner of the contract.
     * @param _duration The duration of the contract before it asks for the winners.
     */
    constructor(
        string memory _league,
        address _owner,
        uint _duration
    )
        payable
        APIConsumer(_league, _duration)
        ERC1155(
            'https://ipfs.io/ipfs/QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn'
        )
    {
        // if (
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('germany')) &&
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('brazil')) &&
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('spain')) &&
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('italy')) &&
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('portugal')) &&
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('england')) &&
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('argentina')) &&
        //     keccak256(abi.encodePacked(_league)) !=
        //     keccak256(abi.encodePacked('france'))
        // ) {
        //     revert InvalidLeague();
        // }
        VerifyLeague.validLeague(_league);
        transferOwnership(_owner);
        i_leagueSize = calculateLeagueSize(_league);
        initialMintValue();
    }

    /**
     * @dev Get the current block number.
     * @return The current Ethereum block number.
     */
    // function getCurrentBlockNumber() external view returns (uint) {
    //     return block.number;
    // }

    /**
     * @dev Get the block number at which the contract was created.
     * @return The block number at contract creation.
     */
    // function getCreationBlockNumber() external view returns (uint) {
    //     return i_creationBlock;
    // }

    /**
     * @dev Calculate the size of the football league associated with this contract.
     * @return leagueSize The number of teams in the league.
     */
    function calculateLeagueSize(
        string memory _league
    ) private pure returns (uint leagueSize) {
        return VerifyLeague.calculateLeagueSize(_league);
    }

    function initialMintValue() private {
        PriceCalculation.initialMintValue(
            i_leagueSize,
            mintPrice,
            c_initialValue
        );
    }

    /**
     * @dev Calculate and store the prices of all NFTs in the league.
     */
    function calculateAllPrices() private {
        delete priceDetails;
        PriceDetails[] memory calculatedPrices = PriceCalculation
            .calculateAllPrices(tokenOwners, transferPrice, i_leagueSize);
        for (uint i = 0; i < calculatedPrices.length; ) {
            priceDetails.push(calculatedPrices[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Get the price of every owner for all NFTs in the league.
     * @return An array of structs containing price details for each NFT.
     */
    function getAllPrices() external view returns (PriceDetails[] memory) {
        return priceDetails;
    }

    /**
     * @dev Get the balance of Ether in the contract's address.
     * @return The current Ether balance of the contract.
     */
    function getPoolPrize() external view returns (uint) {
        return address(this).balance;
    }

    // function setURI(string memory newuri) external onlyOwner {
    //     _setURI(newuri);
    // }

    /**
     * @dev Get the list of token owners for a specific NFT ID.
     * @param id The ID of the NFT to query.
     * @return An array of addresses representing the token owners.
     */
    function tokenOwnersList(uint id) public view returns (address[] memory) {
        return tokenOwners[id];
    }

    /**
     * @dev Create a list of mint prices for all NFTs in the league.
     * @return _mintPriceList An array of mint prices for all NFTs.
     */
    function createMintPriceList()
        public
        view
        returns (uint[] memory _mintPriceList)
    {
        return PriceCalculation.createMintPriceList(i_leagueSize, mintPrice);
    }

    /**
     * @dev Get the total supply of NFTs for all teams in the league.
     * @return An array of total supply of each NFT.
     */
    function getSupply() external view returns (uint[] memory) {
        uint[] memory getAllSupply = new uint[](i_leagueSize);

        for (uint i = 0; i < i_leagueSize; ) {
            getAllSupply[i] = totalSupply(i + 1);
            unchecked {
                i++;
            }
        }
        return getAllSupply;
    }

    /**
     * @dev Mint a specified amount of NFTs representing football teams.
     * @param account The address to receive the minted NFTs.
     * @param id The ID of the football team NFT to mint.
     * @param amount The number of NFTs to mint.
     * @param data Additional data to include with the minted NFTs.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external payable {
        if (winner[0] != 0) {
            revert NotActive();
        }
        // if (amount + totalSupply(id) > 1000000) {
        //     revert NFTReachedCap();
        // }
        if (amount > 1000 && msg.sender != paperAddress) {
            revert MintCap();
        }
        uint timeToEnd = timeLeft();
        if (timeToEnd < i_duration / 2) {
            revert NotActive();
        }
        if (id > i_leagueSize) revert InvalidId();
        // if (totalSupply(id) == 0) mintPrice[id] = (1 ether / 10);
        if (msg.value < mintPrice[id] * amount) {
            revert NotEnoughValue();
        }
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
        _mint(account, id, amount, data);
        
        // tokenOwners[id][account] += amount;
    }

    /**
     * @dev Mint a batch of NFTs representing football teams.
     * @param to The address to receive the minted NFTs.
     * @param ids An array of NFT IDs to mint.
     * @param amounts An array specifying the quantity of each NFT to mint.
     * @param data Additional data to include with the minted NFTs.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external payable {
        if (winner[0] != 0) {
            revert NotActive();
        }
        // require(winner == 0, "Not active");
        // if (timeLeft() < 60 days) revert YouCanOnlyBuy();
        uint timeToEnd = timeLeft();
        if (timeToEnd < i_duration / 2) {
            revert NotActive();
        }
        uint msgValue = msg.value;
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
        for (uint i = 0; i < ids.length; ) {
            // if (amounts[i] + totalSupply(ids[i]) > 1000000) {
            //     revert NFTReachedCap();
            // }
            if (amounts[i] > 1000) {
                revert MintCap();
            }
            // if (totalSupply(ids[i]) == 0) mintPrice[ids[i]] = (1 ether / 10);
            if (msgValue < mintPrice[ids[i]] * amounts[i]) {
                revert NotEnoughValue();
            }
            if (ids[i] > i_leagueSize) revert InvalidId();
            unchecked {
                i++;
            }
        }
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Destroy the contract and transfer its balance to the contract owner.
     * Can only be called after a specific period of time has elapsed.
     * This is to ensure no funds get stuck in the contract.
     */
    function destroy() public {
        if (block.timestamp < i_creationTime + 3 days) revert();
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
        winner[0] = 100;
    }

    /**
     * @dev Updates the list of all the owners of an NFT.
     * @param id The ID of the NFT for which the owners list is updated.
     * @param account The address of the account to add to or remove from the owners list.
     */
    function updateOwnersList(uint id, address account) private {
        bool inTheList = false;
        for (uint i = 0; i < tokenOwners[id].length; ) {
            if (tokenOwners[id][i] == account) inTheList = true;
            if (balanceOf(tokenOwners[id][i], id) == 0) {
                tokenOwners[id][i] = tokenOwners[id][
                    tokenOwners[id].length - 1
                ];
                tokenOwners[id].pop();
            }
            unchecked {
                i++;
            }
        }
        if (!inTheList) tokenOwners[id].push(account);
    }

    /**
     * @dev Allow users to set a price for their NFT.
     * @param id The ID of the NFT for which the price is set.
     * @param price The price in Ether to set for the NFT.
     */
    function _setTokenPrice(address to, uint id, uint price) internal {
        transferPrice[id][to] = price;
        calculateAllPrices();
        // emit TokenPriceSet(id, msg.sender, price);
    }

       function setTokenPrice(uint id, uint price) public {
        if (balanceOf(msg.sender, id) == 0 ) {
            revert NotOwner();
        }
        // if (price == 0) {
        //     revert NotEnoughValue();
        // }
        // require (price > 0, "You need to set a positive price");
        transferPrice[id][msg.sender] = price;
        calculateAllPrices();
        // emit TokenPriceSet(id, msg.sender, price);
    }

    /**
     * @dev Allow a user to buy someone else's NFT. The value sent must match the transfer price.
     * @param id The ID of the NFT to buy.
     * @param amount The quantity of NFTs to buy.
     * @param nftOwner The address of the current owner of the NFT.
     */
    function buyToken(uint id, uint amount, address nftOwner) public payable {
        if (winner[0] != 0) {
            revert NotActive();
        }
        address _owner = owner();

        BuyTokenChecks.buyToken(
            id,
            amount,
            nftOwner,
            winner,
            _owner,
            transferPrice
        );
        // if (
        //     msg.value != transferPrice[id][nftOwner] * amount &&
        //     msg.value != (transferPrice[id][nftOwner] * amount) + 1 &&
        //     msg.value != (transferPrice[id][nftOwner] * amount) - 1
        // ) {
        //     revert NotEnoughValue();
        // }
        if (amount > balanceOf(nftOwner, id)) {
            revert BuyCap();
        }
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
        // uint earnings = ((amount * transferPrice[id][nftOwner] * 999) / 1000);
        // payable(nftOwner).transfer(earnings);
        // payable(_owner).transfer(
        //     ((transferPrice[id][nftOwner] * amount) / 1000)
        // );
        (bool success, ) = address(this).call(
            abi.encodeWithSignature(
                'safeTransferFrom(address,address,uint256,uint256,bytes)',
                nftOwner,
                msg.sender,
                id,
                amount,
                ''
            )
        );
        if (!success) {
            revert CallFailed();
        }
        // emit TokenBought(
        //     id,
        //     nftOwner,
        //     msg.sender,
        //     amount,
        //     (earnings / amount),
        //     block.timestamp
        // );
    }

    /**
     * @dev Calculate how much each NFT was awarded by the end of the season.
     * It is called when the first user calls a payWinner function.
     */
    function calculatePayout() private {
        uint balance = address(this).balance;
        payout[0] = balance / 4; //payout for the 1st place
        payout[1] = balance / 2; //payout for the 10th place
        payout[2] = balance / 4; //payout for the 17th place
        // supply = [
        //     totalSupply(winner[0]),
        //     totalSupply(winner[1]),
        //     totalSupply(winner[2])
        // ];
    }

    /**
     * @dev Pay the holder of NFTs representing the champion, the 10th place, and the 17th place.
     * Can only be called after winners are defined, that is to say, when timeLeft() returns 0.
     */
    function payWinner() public payable {
        if (winner[0] == 0) {
            revert NotActive();
        }
        if (
            balanceOf(msg.sender, winner[0]) == 0 &&
            balanceOf(msg.sender, winner[1]) == 0 &&
            balanceOf(msg.sender, winner[2]) == 0
        ) {
            revert NotOwner();
        }
        if (payoutDefined == false) calculatePayout();
        uint balance;
        uint amount;
        // This contract can receive an ERC1155 token but can't send it anywhere
        address garbage = 0x8431717927C4a3343bCf1626e7B5B1D31E240406;
        if (balanceOf(msg.sender, winner[0]) != 0) {
            balance = balanceOf(msg.sender, winner[0]);
            amount = (payout[0] * balance) / totalSupply(winner[0]);
            _safeTransferFrom(msg.sender, garbage, winner[0], balance, '');
        }
        if (balanceOf(msg.sender, winner[1]) != 0) {
            balance = balanceOf(msg.sender, winner[1]);
            amount += (payout[1] * balance) / totalSupply(winner[1]);
            _safeTransferFrom(msg.sender, garbage, winner[1], balance, '');
        }
        if (balanceOf(msg.sender, winner[2]) != 0) {
            balance = balanceOf(msg.sender, winner[2]);
            amount += (payout[2] * balance) / totalSupply(winner[2]);
            _safeTransferFrom(msg.sender, garbage, winner[2], balance, '');
        }
        payoutDefined = true;
        payable(msg.sender).transfer(amount);
        // emit WinnerPaid(msg.sender, amount);
    }

    // function safeTransferFrom(
    //     /**
    //      * @dev Override function to update the owners' list when transferring NFTs.
    //      * @param from The address transferring the NFT.
    //      * @param to The address receiving the NFT.
    //      * @param id The ID of the NFT being transferred.
    //      * @param amount The quantity of NFTs being transferred.
    //      * @param data Additional data for the transfer.
    //      */
    //     address from,
    //     address to,
    //     uint256 id,
    //     uint256 amount,
    //     bytes memory data
    // ) public override {
    //     super._safeTransferFrom(from, to, id, amount, data);
    //     updateOwnersList(id, to);
    // }

    // function _beforeTokenTransfer(
    //     /**
    //      * @dev Override function required by Solidity.
    //      * @param operator The address that initiates the transfer.
    //      * @param from The address from which tokens are transferred.
    //      * @param to The address to which tokens are transferred.
    //      * @param ids An array of NFT IDs being transferred.
    //      * @param amounts An array specifying the quantity of each NFT being transferred.
    //      * @param data Additional data for the transfer.
    //      */
    //     address operator,
    //     address from,
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) internal override(ERC1155, ERC1155Supply) {
    //     super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    // }

    function _update(
        address from, address to, uint256[] memory ids, uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
        for (uint i; i < ids.length; i++) {
            updateOwnersList(ids[i], to);
            if (transferPrice[ids[i]][to] == 0) _setTokenPrice(to, ids[i], 1000000 ether);
            if (from == address(0)) mintPrice[ids[i]] += values[i] * 0.00033 ether;
            if (from != address(0) && balanceOf(from, ids[i]) == 0) calculateAllPrices();

        }
    }
}
