// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RetirementStorage.sol";
import "./IContract.sol";
import "./ICarbonNft.sol";
import "./CarbonTokenStorage.sol";
import "./CarbonNftStatus.sol";
import "./ICarbonToken.sol";
contract iMRCRetirement is 
    Initializable, 
    ERC721EnumerableUpgradeable, 
    PausableUpgradeable, 
    OwnableUpgradeable, 
    AccessControlUpgradeable, 
    UUPSUpgradeable,
    RetirementStorage
    {
    //constant------------------
    string public constant VERSION = "1.0";
    uint256 public constant VERSION_RELEASE_CANDIDATE = 1;
    bytes32 public constant VERIFIER_ROLE = keccak256('VERIFIER_ROLE');
    bytes32 public constant REGISTER_ROLE = keccak256('REGISTER_ROLE');
    uint256 public RetirementMintCost;
    string public baseURI;
    //event---------------------
    event RetirementMint(address sender,uint256 tokenId);
    event CarbonNftUpdated(uint256 tokenId, string serialNumber, uint256 carbonAmount);
    event Retired(address sender,uint256 carbonAmount);
    //event NftReply(uint256 tokenId,string reply);
    //constructor----------------
    constructor() {
        _disableInitializers();
    }
    //initialize-----------------
    function initialize() initializer public {
        __ERC721_init("GiM-4.2_CarbonRetirementNFT", "GiM-CRNFT");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseURI = "ipfs://QmTkrLAHHUVx4kXSszwCrHPcKUBusjByVvbsnYn7h1d3H7";
    }

    modifier onlyVerifier() {
        require(
            hasRole(VERIFIER_ROLE, _msgSender()),
            'Error: caller is not the verifier'
        );
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }
/*  ############################################
        contract owner function
    ############################################*/
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setYear(uint256 year) public onlyOwner{
        NowYear=year;
    }

    function adminSearchEnrollment(address searchAim) external view virtual onlyOwner returns(string memory){
        require(CompanyList[searchAim].setTime!=0,'Error:this address did not Enrollment');
        return CompanyList[searchAim].CompanyNameEnrollment;
    }

    function setNFTContract(address _iMRCNFTAddress) 
        external
        virtual 
        onlyOwner{
        iMRCNFTAddress = _iMRCNFTAddress;
    }

    function setTokenContract(address _iMRCTokenAddress) 
        external
        virtual 
        onlyOwner{
        iMRCTokenAddress = _iMRCTokenAddress;
    }
/*  ############################################
        add company enrollment
    ############################################*/
    function searchEnrollment() external view virtual returns(string memory){
        require(CompanyList[_msgSender()].setTime!=0,'Error:you need to set Enrollment');
        return CompanyList[_msgSender()].CompanyNameEnrollment;
    }

    function setEnrollment(string memory CompanyId,string memory CompanyName) 
        external 
        virtual 
        whenNotPaused{
        uint256 changeTime = CompanyList[_msgSender()].setTime;
        CompanyList[_msgSender()].CompanyNameEnrollment=CompanyName;
        CompanyList[_msgSender()].CompanyIdEnrollment=CompanyId;
        unchecked{
            changeTime++;
        }
        CompanyList[_msgSender()].setTime=changeTime;
    }
/*  ############################################
        retirement carbon
    ############################################*/
    function NFTRetirement(address to,uint256 tokenId,uint256 Amount)
        external
        virtual
        whenNotPaused returns(bool){
        (uint256 carbonAmount,NftStatus status) = ICarbonNft(iMRCNFTAddress).getCarbonNFTData(tokenId);
        require(Amount==carbonAmount,'Error: your carbon NFT retired from wrong amount!!');
        require(status==NftStatus.VerifiedNFT,'Error: your NFT was already fractionalized or retired');
        RetirementMethodStatus newstatus = RetirementMethodStatus.NFT;
        (uint256 decimals) = ICarbonToken(iMRCTokenAddress).getdemicals();
        uint256 decimal=10**decimals;
        Amount=Amount*decimal;
        _Retirement(to,Amount,newstatus);
        return true;
    }
    function TokenRetirement(address to,uint256 Amount)
        external
        virtual
        whenNotPaused returns(bool){
        (uint256 carbonAmount) = ICarbonToken(iMRCTokenAddress).getCarbonTokenRetirement(to);
        require(Amount==carbonAmount,'Error: your carbon Token retired from wrong amount!!');
        RetirementMethodStatus newstatus = RetirementMethodStatus.Token;
        _Retirement(to,Amount,newstatus);
        return true;
    }
    function _Retirement(address to,uint256 carbonAmount,RetirementMethodStatus _status) 
        internal 
        virtual 
        whenNotPaused{
        require(CompanyList[to].setTime!=0,'Error:you need to set Enrollment');
        uint256 tokenId = mintNFT(to);
        CertificateList[tokenId].Year=NowYear;
        CertificateList[tokenId].CompanyId=CompanyList[to].CompanyIdEnrollment;
        CertificateList[tokenId].CompanyName=CompanyList[to].CompanyNameEnrollment;
        CertificateList[tokenId].RetirementAmount=carbonAmount;
        CertificateList[tokenId].status=_status;
        CertificateList[tokenId].uri=baseURI;
        string memory companyAddRetirementId = CompanyList[to].CompanyIdEnrollment;
        RetirementDataList[companyAddRetirementId].Year=NowYear;
        RetirementDataList[companyAddRetirementId].CompanyName=CompanyList[to].CompanyNameEnrollment;
        uint256 NowCarbonRetiredAmount =  RetirementDataList[companyAddRetirementId].RetirementAmount;
        unchecked{
            NowCarbonRetiredAmount=NowCarbonRetiredAmount+carbonAmount;
        }
        RetirementDataList[companyAddRetirementId].RetirementAmount=NowCarbonRetiredAmount;
        uint256 NowCertificateAmount=RetirementDataList[companyAddRetirementId].CertificateAmount;
        unchecked{
            NowCertificateAmount++;
        }
        RetirementDataList[companyAddRetirementId].CertificateAmount=NowCertificateAmount;
        emit Retired(to, carbonAmount);
    }

        function mintNFT(address to) internal virtual whenNotPaused returns(uint256){
        uint256 newNftId = RetirementTokenCounter;
        unchecked {
            ++newNftId;
        }
        RetirementTokenCounter = newNftId;
        _safeMint(to, newNftId);
        emit RetirementMint(to, newNftId);
        return newNftId;
    }
/*  ############################################
        help function
    ############################################*/
    function getCompanyCarbonRetired(string memory _CompanyId) external view virtual returns(uint256 carbonAmount){
        return RetirementDataList[_CompanyId].RetirementAmount;
    }
}
