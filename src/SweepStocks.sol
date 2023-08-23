// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import {APIConsumer, ConfirmedOwner} from './ChainlinkConsumer.sol';

error NotEnoughValue();
error NotActive();
error InvalidLeague();
error NotOwner();
error MintCap();
error BuyCap();
error NFTReachedCap();
error CallFailed();

// error YouCanOnlyBuy();

/// @custom:security-contact marcelofrayha@gmail.com
contract SweepStocks is ERC1155, ERC1155Supply, ConfirmedOwner, APIConsumer {
    uint[3] public payout;
    uint[3] public supply;
    bool private payoutDefined = false;
    // address private immutable _owner; //contract owner - this will be a multisig or zk wallet
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

    event TokenPriceSet(uint indexed id, address indexed by, uint amount);
    event TokenBought(
        uint indexed id,
        address from,
        address by,
        uint amount,
        uint indexed value,
        uint indexed time
    );

    event TransferValue(
        address indexed from,
        address indexed by,
        uint indexed value
    );

    event WinnerPaid(address indexed owner, uint indexed amount);

    constructor(
        string memory _league
    )
        payable
        APIConsumer(_league)
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
        // _owner = msg.sender;
        transferOwnership(address(0xab9c475dE99c213DB8c9CAaE86478CCEA367f508));
    }

    function getCurrentBlockNumber() public view returns (uint) {
        return block.number;
    }

    function getCreationBlockNumber() public view returns (uint) {
        return i_creationBlock;
    }

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

    function getAllPrices() public view returns (PriceDetails[] memory) {
        return priceDetails;
    }

    function getPoolPrize() public view returns (uint) {
        return address(this).balance;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function tokenOwnersList(uint id) public view returns (address[] memory) {
        return tokenOwners[id];
    }

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

    function getSupply() public view returns (uint[20] memory) {
        uint[20] memory getAllSupply;
        uint size = calculateLeagueSize();

        for (uint i = 0; i < size; i++) {
            getAllSupply[i] = totalSupply(i + 1);
        }
        return getAllSupply;
    }

    //Creates an NFT representing a football team
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
        // if (timeLeft() < 60 days) revert YouCanOnlyBuy();
        if (totalSupply(id) == 0) mintPrice[id] = (1 ether / 100);
        if (msg.value < mintPrice[id] * amount) {
            revert NotEnoughValue();
        }
        //require (msg.value >= mintPrice[id]*amount, "Send more money");
        _mint(account, id, amount, data);
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
        mintPrice[id] += amount * 0.00013 ether;
        updateOwnersList(id, account);
        setTokenPrice(id, 1000000 ether);
        // tokenOwners[id][account] += amount;
    }

    //Creates a batch of NFTs
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
        uint msgValue = msg.value;
        for (uint i = 0; i < ids.length; i++) {
            if (amounts[i] + totalSupply(ids[i]) > 1000000) {
                revert NFTReachedCap();
            }
            // require(amounts[i] + totalSupply(ids[i]) <= 10000000, "The NFT reached its cap");
            if (amounts[i] > 1000) {
                revert MintCap();
            }
            // require(amounts[i] <= 100, "You can only mint 20 in the same transaction");
            if (totalSupply(ids[i]) == 0) mintPrice[ids[i]] = (1 ether / 10);
            if (msgValue < mintPrice[ids[i]] * amounts[i]) {
                revert NotEnoughValue();
            }
            //    require (msg.value >= mintPrice[ids[i]]*amounts[i], "Send more money");
            mintPrice[ids[i]] += amounts[i] * 0.00013 ether;
            // tokenOwners[ids[i]][to] += amounts[i];
            updateOwnersList(ids[i], to);
            setTokenPrice(ids[i], 1000000 ether);
        }
        _mintBatch(to, ids, amounts, data);
        if (!isApprovedForAll(msg.sender, address(this)))
            setApprovalForAll(address(this), true);
    }

    //Allow destroying the contract after 350 days of its creation
    function destroy() public {
        // require(block.timestamp >= i_creationTime + 350 days);
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
        winner = 1000;
    }

    // Updates the list of all the owners of a NFT
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

    //Allow users to set a price for its NFT
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
        emit TokenPriceSet(id, msg.sender, price);
    }

    //Allow user to buy someone else's NFT
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
        if (balanceOf(nftOwner, id) == 0) calculateAllPrices();
        uint earnings = ((amount * transferPrice[id][nftOwner] * 999) / 1000);
        payable(nftOwner).transfer(earnings);
        address _owner = owner();
        payable(_owner).transfer(
            (((transferPrice[id][nftOwner] * 1) * amount) / 1000)
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
        emit TokenBought(
            id,
            nftOwner,
            msg.sender,
            amount,
            (earnings / amount),
            block.timestamp
        );
        emit TransferValue(nftOwner, msg.sender, amount * earnings);
    }

    /*Calculate how much each NFT was awarded by the end of the season 
    It is called when the first user calls a payWinner function*/
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

    //Pays the holder of a NFT representing the champion,
    // the 10th place and the 17th place
    function payWinner() public payable {
        if (winner == 0) {
            revert NotActive();
        }
        // require (winner != 0, "There is no winner");
        if (
            balanceOf(msg.sender, winner) == 0 ||
            balanceOf(msg.sender, winner2) == 0 ||
            balanceOf(msg.sender, winner3) == 0
        ) {
            revert NotOwner();
        }
        // require (balanceOf(msg.sender, winner) != 0 || balanceOf(msg.sender, winner2) != 0
        // || balanceOf(msg.sender, winner3) != 0, "You don't have this NFT");
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
        emit WinnerPaid(msg.sender, amount);
    }

    //This is an override function to update our owners' list
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

    // The following function is override required by Solidity.
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
