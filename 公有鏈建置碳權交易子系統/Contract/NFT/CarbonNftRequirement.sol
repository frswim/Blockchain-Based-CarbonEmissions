// SPDX-License-Identifier: MIT
import "./CarbonNftStatus.sol";
pragma solidity ^0.8.14;
abstract contract CarbonNftRequirementV1 {
    uint256 public NftTokenCounter;
    address public iMRCRetirementAddress;
    mapping(string => bool) public serialNumberApproved;
    struct NFTData {
        string serialNumber;
        string CompanyId;
        string CompanyName;
        uint256 carbonAmount;
        NftStatus status;
        string uri;
        string[] reply;
        address[] replyOwner;
    }
    struct CompanyEnrollment{
        string CompanyIdEnrollment;
        string CompanyNameEnrollment;
    }
    struct CompanyData{
        string CompanyNameEnrollment;
        uint256 carbonAmount;
    }
    mapping(uint256 => NFTData) public nftList;
    mapping(address => CompanyEnrollment) public EnrollmentList;
    mapping(string => CompanyData) public CompanyDataList;
}

abstract contract CarbonNftRequirement is CarbonNftRequirementV1 {}