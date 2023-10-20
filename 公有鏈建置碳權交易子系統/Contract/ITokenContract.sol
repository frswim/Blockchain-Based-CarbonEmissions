// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//使NFT鑄造工廠找到Token工廠
interface ITokenContract {
    function iMRCNFTAddress() external view returns (address);

    //function carbonProjectsAddress() external view returns (address);

    //function carbonProjectVintagesAddress() external view returns (address);

    function iMRCTokenFactoryAddress()
        external
        view
        returns (address);

    //function carbonOffsetBadgesAddress() external view returns (address);

    //function checkERC20(address _address) external view returns (bool);

    //function addERC20(address _address) external;
}