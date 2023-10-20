// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./CarbonNftStatus.sol";

interface ICarbonNft {
    function getCarbonNftStatus(uint256 tokenId)
        external
        view
        returns (NftStatus);
    function getCarbonNFTData(uint256 tokenId)
        external
        view
        returns (
            //uint256,
            uint256,
            NftStatus);
}