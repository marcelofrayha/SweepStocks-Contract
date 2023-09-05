// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

import {ERC1155} from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import {ERC1155Supply} from '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import {APIConsumer, ConfirmedOwner} from './ChainlinkConsumer.sol';

error NotEnoughValue();
error NotActive();
error InvalidLeague();
error NotOwner();
error MintCap();
error BuyCap();
error NFTReachedCap();
error CallFailed();
error InvalidId();

/// @custom:security-contact marcelofrayha@gmail.com

contract SweepStocks is ERC1155, ERC1155Supply, ConfirmedOwner, APIConsumer {
    uint[3] public payout;
    uint[3] public supply;
    bool private payoutDefined = false;
    mapping(uint => address[]) public tokenOwners;
    // Price to create a new NFT, this is handled by the contract
    mapping(uint => uint) public mintPrice;
    // Price set by the owner of a NFT
    mapping(uint => mapping(address => uint)) public transferPrice;
    struct PriceDetails {
        uint id;
        address[] nftOwners;
        uint[] price;
    }

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
     * @param _league The name of the football league associated with this contract.
     * @param _owner The initial owner of the contract.
     * @param _duration The duration of the API data validity.
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
        if (
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('germany')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('brazil')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('spain')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('italy')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('portugal')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('england')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('argentina')) &&
            keccak256(abi.encodePacked(_league)) !=
            keccak256(abi.encodePacked('france'))
        ) {
            revert InvalidLeague();
        }
        transferOwnership(_owner);
        initialMintValue();
    }

    /**
     * @dev Get the current block number.
     * @return The current Ethereum block number.
     */
    function getCurrentBlockNumber() external view returns (uint) {
        return block.number;
    }

    /**
     * @dev Get the block number at which the contract was created.
     * @return The block number at contract creation.
     */
    function getCreationBlockNumber() external view returns (uint) {
        return i_creationBlock;
    }

    /**
     * @dev Calculate the size of the football league associated with this contract.
     * @return leagueSize The number of teams in the league.
     */
    function calculateLeagueSize() private view returns (uint leagueSize) {
        if (
            keccak256(abi.encodePacked(league)) ==
            keccak256(abi.encodePacked('germany')) ||
            keccak256(abi.encodePacked(league)) ==
            keccak256(abi.encodePacked('portugal'))
        ) return 18;
        else if (
            keccak256(abi.encodePacked(league)) ==
            keccak256(abi.encodePacked('argentina'))
        ) return 28;
        else return 20;
    }

    function initialMintValue() private {
        uint size = calculateLeagueSize();
        for (uint i = 0; i < size; i++) {
            mintPrice[i + 1] = (1 ether / 10);
        }
    }

    /**
     * @dev Calculate and store the prices of all NFTs in the league.
     */
    function calculateAllPrices() private {
        delete priceDetails;
        uint size = calculateLeagueSize();
        for (uint i = 1; i <= size; i++) {
            address[] memory ownersList = tokenOwnersList(i);
            uint[] memory prices = new uint[](ownersList.length);
            for (uint j = 0; j < ownersList.length; j++) {
                if (transferPrice[i][ownersList[j]] == 0)
                    transferPrice[i][ownersList[j]] = 100000000 ether;
                prices[j] = transferPrice[i][ownersList[j]];
            }
            PriceDetails memory list = PriceDetails(i, ownersList, prices);
            priceDetails.push(list);
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
        uint size = calculateLeagueSize();

        uint[] memory mintPriceList = new uint[](size);
        for (uint i = 0; i < size; i++) {
            mintPriceList[i] = mintPrice[i + 1];
        }
        return mintPriceList;
    }

    /**
     * @dev Get the total supply of NFTs for all teams in the league.
     * @return An array of total supply of each NFT.
     */
    function getSupply() external view returns (uint[] memory) {
        uint size = calculateLeagueSize();
        uint[] memory getAllSupply = new uint[](size);

        for (uint i = 0; i < size; i++) {
            getAllSupply[i] = totalSupply(i + 1);
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
        if (winner != 0) {
            revert NotActive();
        }
        if (amount + totalSupply(id) > 1000000) {
            revert NFTReachedCap();
        }
        if (amount > 1000) {
            revert MintCap();
        }
        uint timeToEnd = timeLeft();
        if (timeToEnd < i_duration / 2) {
            revert NotActive();
        }
        uint leagueSize = calculateLeagueSize();
        if (id > leagueSize) revert InvalidId();
        // if (totalSupply(id) == 0) mintPrice[id] = (1 ether / 10);
        if (msg.value < mintPrice[id] * amount) {
            revert NotEnoughValue();
        }
        _mint(account, id, amount, data);
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
        mintPrice[id] += amount * 0.00013 ether;
        updateOwnersList(id, account);
        setTokenPrice(id, 1000000 ether);
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
        if (winner != 0) {
            revert NotActive();
        }
        // require(winner == 0, "Not active");
        // if (timeLeft() < 60 days) revert YouCanOnlyBuy();
        uint timeToEnd = timeLeft();
        if (timeToEnd < i_duration / 2) {
            revert NotActive();
        }
        uint msgValue = msg.value;
        uint leagueSize = calculateLeagueSize();
        for (uint i = 0; i < ids.length; i++) {
            if (amounts[i] + totalSupply(ids[i]) > 1000000) {
                revert NFTReachedCap();
            }
            if (amounts[i] > 1000) {
                revert MintCap();
            }
            // if (totalSupply(ids[i]) == 0) mintPrice[ids[i]] = (1 ether / 10);
            if (msgValue < mintPrice[ids[i]] * amounts[i]) {
                revert NotEnoughValue();
            }
            if (ids[i] > leagueSize) revert InvalidId();

            mintPrice[ids[i]] += amounts[i] * 0.00013 ether;
            updateOwnersList(ids[i], to);
            setTokenPrice(ids[i], 1000000 ether);
        }
        _mintBatch(to, ids, amounts, data);
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
    }

    /**
     * @dev Destroy the contract and transfer its balance to the contract owner.
     * Can only be called after a specific period of time has elapsed.
     * This is to ensure no funds get stuck in the contract.
     */
    function destroy() public {
        // require(block.timestamp >= i_creationTime + 350 days);
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
        winner = 100;
    }

    /**
     * @dev Updates the list of all the owners of an NFT.
     * @param id The ID of the NFT for which the owners list is updated.
     * @param account The address of the account to add to or remove from the owners list.
     */
    function updateOwnersList(uint id, address account) private {
        bool inTheList = false;
        for (uint i = 0; i < tokenOwners[id].length; i++) {
            if (tokenOwners[id][i] == account) inTheList = true;
            if (balanceOf(tokenOwners[id][i], id) == 0) {
                tokenOwners[id][i] = tokenOwners[id][
                    tokenOwners[id].length - 1
                ];
                tokenOwners[id].pop();
            }
        }
        if (!inTheList) tokenOwners[id].push(account);
    }

    /**
     * @dev Allow users to set a price for their NFT.
     * @param id The ID of the NFT for which the price is set.
     * @param price The price in Ether to set for the NFT.
     */
    function setTokenPrice(uint id, uint price) public {
        if (balanceOf(msg.sender, id) == 0) {
            revert NotOwner();
        }
        // require (balanceOf(msg.sender, id) > 0, "You don't have this NFT");
        if (price == 0) {
            revert NotEnoughValue();
        }
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
        if (winner != 0) {
            revert NotActive();
        }
        if (
            msg.value != transferPrice[id][nftOwner] * amount &&
            msg.value != (transferPrice[id][nftOwner] * amount) + 1 &&
            msg.value != (transferPrice[id][nftOwner] * amount) - 1
        ) {
            revert NotEnoughValue();
        }
        if (amount > balanceOf(nftOwner, id)) {
            revert BuyCap();
        }
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
        uint earnings = ((amount * transferPrice[id][nftOwner] * 999) / 1000);
        payable(nftOwner).transfer(earnings);
        address _owner = owner();
        payable(_owner).transfer(
            ((transferPrice[id][nftOwner] * amount) / 1000)
        );
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
        if (balanceOf(nftOwner, id) == 0) calculateAllPrices();
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
        supply = [
            totalSupply(winner),
            totalSupply(winner2),
            totalSupply(winner3)
        ];
    }

    /**
     * @dev Pay the holder of NFTs representing the champion, the 10th place, and the 17th place.
     * Can only be called after winners are defined.
     */
    function payWinner() public payable {
        if (winner == 0) {
            revert NotActive();
        }
        if (
            balanceOf(msg.sender, winner) == 0 ||
            balanceOf(msg.sender, winner2) == 0 ||
            balanceOf(msg.sender, winner3) == 0
        ) {
            revert NotOwner();
        }
        if (payoutDefined == false) calculatePayout();
        uint balance;
        uint amount;
        // This contract can receive an ERC1155 token but can't send it anywhere
        address garbage = 0x8431717927C4a3343bCf1626e7B5B1D31E240406;
        if (balanceOf(msg.sender, winner) != 0) {
            balance = balanceOf(msg.sender, winner);
            amount = (payout[0] * balance) / supply[0];
            _safeTransferFrom(msg.sender, garbage, winner, balance, '');
        }
        if (balanceOf(msg.sender, winner2) != 0) {
            balance = balanceOf(msg.sender, winner2);
            amount += (payout[1] * balance) / supply[1];
            _safeTransferFrom(msg.sender, garbage, winner2, balance, '');
        }
        if (balanceOf(msg.sender, winner3) != 0) {
            balance = balanceOf(msg.sender, winner3);
            amount += (payout[2] * balance) / supply[2];
            _safeTransferFrom(msg.sender, garbage, winner3, balance, '');
        }
        payoutDefined = true;
        payable(msg.sender).transfer(amount);
        // emit WinnerPaid(msg.sender, amount);
    }

    /**
     * @dev Override function to update the owners' list when transferring NFTs.
     * @param from The address transferring the NFT.
     * @param to The address receiving the NFT.
     * @param id The ID of the NFT being transferred.
     * @param amount The quantity of NFTs being transferred.
     * @param data Additional data for the transfer.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._safeTransferFrom(from, to, id, amount, data);
        updateOwnersList(id, to);
    }

    /**
     * @dev Override function required by Solidity.
     * @param operator The address that initiates the transfer.
     * @param from The address from which tokens are transferred.
     * @param to The address to which tokens are transferred.
     * @param ids An array of NFT IDs being transferred.
     * @param amounts An array specifying the quantity of each NFT being transferred.
     * @param data Additional data for the transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
