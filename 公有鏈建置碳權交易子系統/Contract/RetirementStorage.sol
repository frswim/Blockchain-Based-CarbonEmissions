// SPDX-License-Identifier: MIT
import "./RetirementMethodStatus.sol";
pragma solidity ^0.8.14;
abstract contract RetirementStorage {
    uint256 public RetirementTokenCounter;
    address public iMRCNFTAddress;
    address public iMRCTokenAddress;
    uint256 public NowYear;
    struct CompanyEnrollment{
        string CompanyIdEnrollment;
        string CompanyNameEnrollment;
        uint256 setTime;
    }
    struct RetirementCertificate {
        uint256 Year;
        string CompanyId;
        string CompanyName;
        uint256 RetirementAmount;
        RetirementMethodStatus status;
        string uri;
        string[] reply;
        address[] replyOwner;
    }
    struct RetirementData {
        uint256 Year;
        string CompanyName;
        uint256 RetirementAmount;
        uint256 CertificateAmount;
        string[] reply;
        address[] replyOwner;
    }
    mapping(address=>CompanyEnrollment) public CompanyList;
    mapping(uint256=>RetirementCertificate) public CertificateList;
    mapping(string=>RetirementData) public RetirementDataList;
}

abstract contract CarbonRetirementContract is RetirementStorage {}