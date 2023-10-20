// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

//Token鑄造工廠所需介面
interface IiMRCTokenFactory {
    function bridgeFeeReceiverAddress()
        external
        view
        returns (address receiver);

    function bridgeFeeBurnAddress() external view returns (address burner);

    function getBridgeFeeAndBurnAmount(uint256 quantity)
        external
        view
        returns (uint256 feeAmount, uint256 burnAmount);

    function increaseTotalRetired(uint256 amount) external;

    function allowedBridges(address user) external view returns (bool);

    function owner() external view returns (address);
}