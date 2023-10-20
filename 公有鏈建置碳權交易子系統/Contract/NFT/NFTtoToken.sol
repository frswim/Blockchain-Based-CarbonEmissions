// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

abstract contract NFTtoToken {
    address public contractRegistry;
    address[] public deployedContracts;
    mapping(uint256 => address) public pvIdtoERC20;
}