// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract CarbonTokenStorage {
    //uint256 public projectVintageTokenId;
    address public contractRegistry;
    address public iMRCRetirementAddress;
    uint256 public TokenCounter;
    struct RetireAmount{
        uint256 retireAmount;
    }
    mapping(address => uint256) public minterToId;
    mapping(address => RetireAmount) public getRetiredAmount;
}

abstract contract TokenStorage is CarbonTokenStorage {}