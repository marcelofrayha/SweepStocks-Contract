// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

import {Chainlink, ChainlinkClient} from '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import {ConfirmedOwner} from '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import {AutomationCompatibleInterface} from '@chainlink/contracts/src/v0.8/AutomationCompatible.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

error UpkeepNotNeeded();
error YouHaveToWait();
error AlreadyHaveWinner();

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
    uint public immutable i_duration;
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

    /**
     * @dev Constructor function to initialize the APIConsumer contract.
     * @param _league The name of the football league associated with this contract.
     * @param _duration The duration of the API data validity.
     */
    constructor(
        string memory _league,
        uint _duration
    ) ConfirmedOwner(msg.sender) {
        league = _league;
        i_duration = _duration;
        i_creationTime = block.timestamp;
        i_creationBlock = block.number;
        // string memory baseURL = "http://api.football-data.org/v4/competitions/";
        // string memory endpoint = "/standings";
        // URL = baseURL.concat(league).concat(endpoint);
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); //Polygon LINK Token
        setChainlinkOracle(0x7ca7215c6B8013f249A195cc107F97c4e623e5F5); //Polygon Oracle run by OracleSpace Labs
        // setChainlinkOracle(0xc7086899d02Cdd5C1B0cDa32CB50aaB9a2edC416); //Polygon Oracle run by me
        //i_jobId = "3d2529ce26a74c9d9e593750d94950c9"; //single response job
        // i_jobId = "cd3a5f8dcac245e9a3ff58d59b445595"; //multi response job
        i_jobId = '0bf991b9f60b4f72964c1e6afc34f099'; //multi response job from Labs
        i_fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18
    }

    /**
     * @dev Register and predict the ID for chainlink upkeep (automation).
     * This function approves the LINK token transfer and registers the upkeep with Keeper.
     */
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
            uint96(i_fee * 5)
        );
        i_link.approve(address(i_registrar), params.amount);
        i_registrar.registerUpkeep(params);
    }

    /**
     * @dev Get the time left to check upkeep, call the oracle for the winners and close the NFT market.
     * @return The time left in days.
     */
    function timeLeft() public view returns (uint) {
        int time = (int(i_creationTime) +
            (1 + int(i_duration)) *
            1 days -
            int(block.timestamp));
        return time > 0 ? uint(time) / 86400 : 0;
    }

    /**
     * @dev Check if upkeep is needed based on the remaining time and the stopUpkeep flag.
     * @return upkeepNeeded Whether upkeep is needed.
     * @return performData Additional data for performing upkeep (not used in this implementation).
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData */) {
        if (timeLeft() == 0 && !stopUpkeep) upkeepNeeded = true;
        else upkeepNeeded = false;
        return (upkeepNeeded, '');
    }

    /**
     * @dev Perform upkeep by requesting the winner when necessary.
     * If upkeep is not needed, it reverts with an error.
     * If it is, thas stopUpkeep flag becomes true to prevent more calls.
     */
    function performUpkeep(bytes calldata /*performData */) public {
        if (timeLeft() != 0 || stopUpkeep) revert UpkeepNotNeeded();
        (bool upkeepNeeded, ) = checkUpkeep('');
        if (!upkeepNeeded) {
            revert UpkeepNotNeeded();
        } else {
            stopUpkeep = true;
            requestWinner();
        }
    }

    /**
     * @dev Request the winner from the Chainlink Oracle.
     * It sends a Chainlink request with the league parameter to the Oracle.
     * @return requestId The ID of the Chainlink request.
     */
    function requestWinner() public returns (bytes32 requestId) {
        if (timeLeft() != 0) revert YouHaveToWait();
        if (winner != 0) revert AlreadyHaveWinner();
        Chainlink.Request memory req = buildChainlinkRequest(
            i_jobId,
            address(this),
            this.fulfillOracleRequest.selector
        );

        req.add('league', league);
        // Sends the request
        return sendChainlinkRequest(req, i_fee);
    }

    /**
     * @dev Receive and process the response from the Chainlink Oracle.
     * @param _requestId The ID of the Chainlink request.
     * @param _winner An array containing the 1st place's data.
     * @param _winner2 An array containing the 10th place's data.
     * @param _winner3 An array containing the 17th place's data.
     */
    function fulfillOracleRequest(
        bytes32 _requestId,
        uint[] memory _winner,
        uint[] memory _winner2,
        uint[] memory _winner3
    ) public virtual recordChainlinkFulfillment(_requestId) {
        if (timeLeft() != 0) revert YouHaveToWait();
        if (winner != 0) revert AlreadyHaveWinner();
        winner = _winner[0];
        winner2 = _winner2[0];
        winner3 = _winner3[0];
        emit RequestWinner(_requestId, winner, winner2, winner3);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    // function withdrawLink() public onlyOwner {
    //     LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    //     require(
    //         link.transfer(msg.sender, link.balanceOf(address(this))),
    //         'Unable to transfer'
    //     );
    // }
}
