// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import '@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol';

interface ILinkToken {
    function transferAndCall(
        address receiver,
        uint amount,
        bytes calldata data
    ) external returns (bool success);

    function balanceOf(address user) external view returns (uint);

    function approve(address spender, uint amount) external;

    function transfer(address _to, uint _amount) external;
}

interface KeepersRegistry {
    function getRegistrar() external view returns (address);
}

contract UpkeepCreator {
    address public REGISTRY_ADDRESS =
        0x02777053d6764996e594c3E88AF1D58D5363a2e6; //Kovan testnet
    address public ERC677_LINK_ADDRESS =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    /* 
    register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    )
    */
    bytes4 private constant FUNC_SELECTOR =
        bytes4(
            keccak256(
                'register(string,bytes,address,uint32,address,bytes,uint96,uint8)'
            )
        );
    uint public minFundingAmount = 1000000000000000000; //5 LINK
    uint8 public SOURCE = 110;

    ILinkToken ERC677Link = ILinkToken(ERC677_LINK_ADDRESS);

    //Note: make sure to fund this contract with LINK before calling createUpkeep
    function createUpkeep(
        address contractAddressToAutomate,
        string memory upkeepName,
        uint32 gasLimit
    ) external {
        address registarAddress = KeepersRegistry(REGISTRY_ADDRESS)
            .getRegistrar();
        uint96 amount = uint96(minFundingAmount);
        bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR,
            upkeepName,
            hex'',
            contractAddressToAutomate,
            gasLimit,
            msg.sender,
            hex'',
            amount,
            SOURCE
        );
        ERC677Link.transferAndCall(registarAddress, minFundingAmount, data);
        ERC677Link.transfer(contractAddressToAutomate, 100000000000000000);
    }
}
