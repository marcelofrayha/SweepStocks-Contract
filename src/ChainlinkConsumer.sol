// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

import {Chainlink, ChainlinkClient} from '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import {ConfirmedOwner} from '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import {AutomationCompatibleInterface} from '@chainlink/contracts/src/v0.8/AutomationCompatible.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import {OraclesMode} from './lib/OraclesMode.sol';
import {VerifyLeague} from './lib/VerifyLeague.sol';

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
    LinkTokenInterface private constant i_link =
        LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    KeeperRegistrarInterface private constant i_registrar =
        KeeperRegistrarInterface(0x57A4a13b35d25EE78e084168aBaC5ad360252467);
    using Chainlink for Chainlink.Request;
    using OraclesMode for uint[];

    bool private stopUpkeep = false;
    uint8 public winnerResponsesReceived;
    uint8[][3] public winnerResponses;
    // uint8[] public winner2Responses;
    // uint8[] public winner3Responses;
    uint8[3] public winner;
    bytes32[2] requestIds;
    uint internal immutable i_duration;
    uint internal immutable i_creationTime;
    uint internal immutable i_creationBlock;
    uint256 private immutable i_fee;
    bytes32[2] private i_jobId = [
        bytes32('cd3a5f8dcac245e9a3ff58d59b445595'),
        bytes32('0bf991b9f60b4f72964c1e6afc34f099')
    ];
    address[2] private c_oracles = [
        address(0xc7086899d02Cdd5C1B0cDa32CB50aaB9a2edC416),
        address(0x7ca7215c6B8013f249A195cc107F97c4e623e5F5)
    ];
    // string private URL;
    string internal league;

    mapping(uint => uint) valueCounts;
    mapping(uint => uint) valueCountsWinner2;
    mapping(uint => uint) valueCountsWinner3;

    // event RequestWinner(
    //     bytes32 indexed requestId,
    //     uint256 winner,
    //     uint256 winner2,
    //     uint256 winner3
    // );

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
        // setChainlinkOracle(0x7ca7215c6B8013f249A195cc107F97c4e623e5F5); //Polygon Oracle run by OracleSpace Labs
        // setChainlinkOracle(0xc7086899d02Cdd5C1B0cDa32CB50aaB9a2edC416); //Polygon Oracle run by me
        //i_jobId = "3d2529ce26a74c9d9e593750d94950c9"; //single response job
        // i_jobId = "cd3a5f8dcac245e9a3ff58d59b445595"; //multi response job
        // i_jobId = '0bf991b9f60b4f72964c1e6afc34f099'; //multi response job from Labs
        i_fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18
    }

    /**
     * @dev Register and predict the ID for chainlink upkeep (automation).
     * This function approves the LINK token transfer and registers the upkeep with Keeper.
     */
    function registerAndPredictID() external {
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
        return VerifyLeague.timeLeft(i_creationTime, i_duration);
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
    function performUpkeep(bytes calldata /*performData */) external {
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
    function requestWinner() private returns (bytes32[2] memory requestId) {
        if (timeLeft() != 0) revert YouHaveToWait();
        if (winner[0] != 0) revert AlreadyHaveWinner();
        for (uint i = 0; i < c_oracles.length; ) {
            Chainlink.Request memory req = buildChainlinkRequest(
                i_jobId[i],
                address(this),
                this.fulfillOracleRequest.selector
            );

            req.add('league', league);
            // Sends the request
            bytes32 request = sendChainlinkRequestTo(c_oracles[i], req, i_fee);
            requestIds[i] = request;
            unchecked {
                i++;
            }
        }

        return requestIds;
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
        uint[] calldata _winner,
        uint[] calldata _winner2,
        uint[] calldata _winner3
    ) external virtual recordChainlinkFulfillment(_requestId) {
        if (timeLeft() != 0) revert YouHaveToWait();
        if (winner[0] != 0) revert AlreadyHaveWinner();

        recordWinnerResponse(_winner[0]);
        recordWinner2Response(_winner2[0]);
        recordWinner3Response(_winner3[0]);
        winnerResponsesReceived++;
        if (winnerResponsesReceived == i_jobId.length) {
            // If any of the winners are not calculated, wait for more responses.
            calculateModes();
        }
        // emit RequestWinner(_requestId, winner[0], winner[1], winner[2]);
    }

    /**
     * Functions to calculate the mode of Oracles answers
     */
    // Function to record oracle responses for winner
    function recordWinnerResponse(uint response) private {
        winnerResponses[0].push(uint8(response));
    }

    // Function to record oracle responses for winner2
    function recordWinner2Response(uint response) private {
        winnerResponses[1].push(uint8(response));
    }

    // Function to record oracle responses for winner3
    function recordWinner3Response(uint response) private {
        winnerResponses[2].push(uint8(response));
    }

    // Function to calculate the modes for all three variables
    function calculateModes() private {
        winner[0] = OraclesMode.calculateMode(winnerResponses[0], valueCounts);
        winner[1] = OraclesMode.calculateMode(
            winnerResponses[1],
            valueCountsWinner2
        );
        winner[2] = OraclesMode.calculateMode(
            winnerResponses[2],
            valueCountsWinner3
        );
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
