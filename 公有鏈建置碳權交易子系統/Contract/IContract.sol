// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//各種合約地址
interface IContract {
    function iMRCNFTAddress() external view returns (address);
    function iMRCTokenAddress() external view returns (address);
    function iMRCRetirementAddress() external view returns (address);
}