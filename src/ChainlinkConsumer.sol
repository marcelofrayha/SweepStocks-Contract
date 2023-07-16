// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 .0;

import "../node_modules/@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../node_modules/@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

// library StringUtils {
//     function concat(string memory a, string memory b) internal pure returns (string memory) {
//         return string(abi.encodePacked(a, b));
//     }
// }

contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    // using StringUtils for string;
    using Chainlink for Chainlink.Request;

    uint256 public winner;
    uint256 public winner2;
    uint256 public winner3;
    uint public immutable creationTime;
    uint public creationBlock;
    bytes32 private immutable jobId;
    uint256 private immutable fee;
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
        creationTime = block.timestamp;
        creationBlock = block.number;
        // URL = baseURL.concat(league).concat(endpoint);
        // setChainlinkOracle(0xc7086899d02Cdd5C1B0cDa32CB50aaB9a2edC416); //Polygon Oracle run by me
        setChainlinkOracle(0x7ca7215c6B8013f249A195cc107F97c4e623e5F5); //Polygon Oracle run by OracleSpace Labs
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); //Polygon LINK Token
        //jobId = "3d2529ce26a74c9d9e593750d94950c9"; //single response job
        // jobId = "cd3a5f8dcac245e9a3ff58d59b445595"; //multi response job
        jobId = "0bf991b9f60b4f72964c1e6afc34f099"; //multi response job from Labs
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18
    }

    /**
     * Create a Chainlink request to retrieve API response, then find the target
     * data.
     */
    function requestWinner() public virtual returns (bytes32 requestId) {
        // if (block.timestamp < creationTime + 200 days) { revert(); }
        // require(block.timestamp >= creationTime + 200 days);
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillOracleRequest.selector
        );

        // req.add(
        //     "get",
        //     URL
        // );

        req.add("league", league);

        // Sends the request
        return sendChainlinkRequest(req, fee);
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
            "Unable to transfer"
        );
    }
}
