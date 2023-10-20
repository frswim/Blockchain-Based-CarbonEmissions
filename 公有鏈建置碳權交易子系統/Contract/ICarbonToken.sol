// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICarbonToken {
    function getCarbonTokenRetirement(address to) external view returns (uint256);
    function getdemicals() external view returns (uint256);
}