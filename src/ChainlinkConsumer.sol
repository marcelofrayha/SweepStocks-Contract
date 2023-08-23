// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import '@chainlink/contracts/src/v0.8/AutomationCompatible.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

error UpkeepNotNeeded();
error YouHaveToWait(uint time);

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

contract APIConsumer is
    ChainlinkClient,
    ConfirmedOwner,
    AutomationCompatibleInterface
{
    // using StringUtils for string;
    LinkTokenInterface public constant i_link =
        LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    KeeperRegistrarInterface public constant i_registrar =
        KeeperRegistrarInterface(0x57A4a13b35d25EE78e084168aBaC5ad360252467);
    using Chainlink for Chainlink.Request;
    bool public stopUpkeep = false;
    uint256 public winner;
    uint256 public winner2;
    uint256 public winner3;
    uint public immutable i_creationTime;
    uint public immutable i_creationBlock;
    bytes32 private immutable i_jobId;
    uint256 private immutable i_fee;
    // string private URL;
    string public league;
    event RequestWinner(
        bytes32 indexed requestId,
        uint256 winner,
        uint256 winner2,
        uint256 winner3
    );

    constructor(string memory _league) ConfirmedOwner(msg.sender) {
        // string memory baseURL = "http://api.football-data.org/v4/competitions/";
        // string memory endpoint = "/standings";
        league = _league;
        i_creationTime = block.timestamp;
        i_creationBlock = block.number;
        // URL = baseURL.concat(league).concat(endpoint);
        // setChainlinkOracle(0xc7086899d02Cdd5C1B0cDa32CB50aaB9a2edC416); //Polygon Oracle run by me
        setChainlinkOracle(0x7ca7215c6B8013f249A195cc107F97c4e623e5F5); //Polygon Oracle run by OracleSpace Labs
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); //Polygon LINK Token
        //i_jobId = "3d2529ce26a74c9d9e593750d94950c9"; //single response job
        // i_jobId = "cd3a5f8dcac245e9a3ff58d59b445595"; //multi response job
        i_jobId = '0bf991b9f60b4f72964c1e6afc34f099'; //multi response job from Labs
        i_fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18
    }

    function registerAndPredictID() public {
        // LINK must be approved for transfer - this can be done every time or once
        // with an infinite approval
        RegistrationParams memory params = RegistrationParams(
            league,
            '',
            address(this),
            2500000,
            msg.sender,
            '',
            '',
            uint96(i_fee * 7)
        );
        i_link.approve(address(i_registrar), params.amount);
        i_registrar.registerUpkeep(params);
    }

    function timeLeft() public view returns (uint) {
        uint time = (i_creationTime + 20 days - block.timestamp);
        return time > 0 ? time / 86400 : 0;
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData */) {
        if (timeLeft() == 0 && !stopUpkeep) upkeepNeeded = true;
        else upkeepNeeded = false;
        return (upkeepNeeded, '');
    }

    function performUpkeep(bytes calldata /*performData */) public {
        // if (timeLeft() != 0 || stopUpkeep) revert UpkeepNotNeeded();
        (bool upkeepNeeded, ) = checkUpkeep('');
        if (!upkeepNeeded) {
            revert UpkeepNotNeeded();
        } else {
            stopUpkeep = true;
            requestWinner();
        }
    }

    /**
     * Create a Chainlink request to retrieve API response, then find the target
     * data.
     */

    function requestWinner() public returns (bytes32 requestId) {
        // if (timeLeft() != 0) revert YouHaveToWait(
        //     timeLeft()
        // );
        // if (block.timestamp < i_creationTime + 200 days) { revert(); }
        // require(block.timestamp >= i_creationTime + 200 days);
        Chainlink.Request memory req = buildChainlinkRequest(
            i_jobId,
            address(this),
            this.fulfillOracleRequest.selector
        );

        // req.add(
        //     "get",
        //     URL
        // );

        req.add('league', league);

        // Sends the request
        return sendChainlinkRequest(req, i_fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfillOracleRequest(
        bytes32 _requestId,
        uint[] memory _winner,
        uint[] memory _winner2,
        uint[] memory _winner3
    ) public virtual recordChainlinkFulfillment(_requestId) {
        winner = _winner[0];
        winner2 = _winner2[0];
        winner3 = _winner3[0];
        emit RequestWinner(_requestId, winner, winner2, winner3);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            'Unable to transfer'
        );
    }
}
