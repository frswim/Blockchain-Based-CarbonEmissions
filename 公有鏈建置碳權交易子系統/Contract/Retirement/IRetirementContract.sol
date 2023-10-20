// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//各種合約地址
interface IRetirementContract {
    function NFTRetirement(address to,uint256 tokenId,uint256 carbonAmount) external returns (bool);
    function TokenRetirement(address to,uint256 carbonAmount) external returns (bool);
}