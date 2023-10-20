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
import "./CarbonNftRequirement.sol";
import "./ICarbonNft.sol";
import "./IContract.sol";
import "./NFTtoToken.sol";
import "./IRetirementContract.sol";

contract iMRCNFT is 
    ICarbonNft,
    Initializable, 
    ERC721EnumerableUpgradeable, 
    PausableUpgradeable, 
    OwnableUpgradeable, 
    AccessControlUpgradeable, 
    UUPSUpgradeable, 
    CarbonNftRequirement,
    NFTtoToken
    {
    //constant------------------
    string public constant VERSION = "1.0";
    uint256 public constant VERSION_RELEASE_CANDIDATE = 1;
    bytes32 public constant VERIFIER_ROLE = keccak256('VERIFIER_ROLE');
    bytes32 public constant REGISTER_ROLE = keccak256('REGISTER_ROLE');
    uint256 public CarbonNftMintCost;
    uint256 public CarbonNftMaxSupply;
    string public baseURI;
    //event---------------------
    event CarbonNftMint(address sender,uint256 tokenId);
    event CarbonNftUpdated(uint256 tokenId, string serialNumber, uint256 carbonAmount);
    event CarbonNftStatus(uint256 tokenId, NftStatus status);
    event CarbonNftFraction(uint256 tokenId, uint256 carbonAmount);
    event CarbonNftRetired(uint256 tokenId, uint256 carbonAmount);
    event NftReply(uint256 tokenId,address from,string reply);
    //constructor----------------
    constructor() {
        _disableInitializers();
    }
    //initialize-----------------
    function initialize() initializer public {
        __ERC721_init("GiM-4.2_CarbonNFT", "GiM-CNFT");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
        CarbonNftMintCost=0;
        CarbonNftMaxSupply=1000;
        baseURI = "ipfs://QmTkrLAHHUVx4kXSszwCrHPcKUBusjByVvbsnYn7h1d3H7";
    }

    modifier onlyVerifier() {
        require(
            hasRole(VERIFIER_ROLE, _msgSender()),
            'Error: caller is not the verifier'
        );
        _;
    }

    /*modifier onlyRegister() {
        require(
            hasRole(REGISTER_ROLE, _msgSender()),
            'Error: caller is not the verifier'
        );
        _;
    }*/

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

    function setCost(uint256 _newCost) public onlyOwner() {
        CarbonNftMintCost = _newCost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner() {
        CarbonNftMaxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setResgistryContract(address _contractRegistry) 
        external
        virtual 
        onlyOwner{
        contractRegistry = _contractRegistry;
    }

    function setRetirementContract(address _iMRCRetirementAddress) 
        external
        virtual  
        onlyOwner{
        iMRCRetirementAddress = _iMRCRetirementAddress;
    }

    function setCompanyEnrollment(
        address _setaddress, 
        string calldata _CompanyIdEnrollment,
        string calldata _CompanyNameEnrollment) 
        external
        virtual  
        onlyOwner{
        EnrollmentList[_setaddress].CompanyIdEnrollment = _CompanyIdEnrollment;
        EnrollmentList[_setaddress].CompanyNameEnrollment = _CompanyNameEnrollment;
        setCompanyDataName(_CompanyIdEnrollment,_CompanyNameEnrollment);
    }

    function setCompanyDataName(
        string calldata _CompanyIdEnrollment,
        string calldata _CompanyNameEnrollment
        ) internal virtual{
        CompanyDataList[_CompanyIdEnrollment].CompanyNameEnrollment = _CompanyNameEnrollment;
    }
/*  ############################################
        nft mint
        address,newNftId
    ############################################*/
    function mintEmptyNft(address to) public virtual whenNotPaused {
        uint256 newNftId = NftTokenCounter;
        require(NftTokenCounter<CarbonNftMaxSupply,'Error: NFT no left!!!');
        unchecked {
            ++newNftId;
        }
        NftTokenCounter = newNftId;
        _safeMint(to, newNftId);
        nftList[newNftId].uri = string(abi.encodePacked(baseURI, "/carbonNFT_notVerify.json"));
        nftList[newNftId].status = NftStatus.BatchNFT;
        nftList[newNftId].CompanyId = EnrollmentList[to].CompanyIdEnrollment;
        nftList[newNftId].CompanyName = EnrollmentList[to].CompanyNameEnrollment;
        emit CarbonNftMint(to, newNftId);
    }
/*  ############################################
        carbon tokenize
    ############################################*/
    function tokenize(
        address to,
        string calldata serialNumber,
        uint256 carbonAmount
    ) external virtual onlyVerifier whenNotPaused {
        mintEmptyNft(to);
        _updateCarbonNftData(NftTokenCounter, serialNumber, carbonAmount);
    }
/*  ############################################
        nft update data
        tokenid,serialNumber,carbonAmount,uri
    ############################################*/
    function updateCarbonNftWithData(
        uint256 tokenId,
        string memory serialNumber,
        uint256 carbonAmount
    ) external virtual whenNotPaused {
        require(
            ownerOf(tokenId) == _msgSender() ||
                hasRole(VERIFIER_ROLE, _msgSender()),
            'Error: update only by owner or verifier'
        );
        _updateCarbonNftData(tokenId, serialNumber, carbonAmount);
    }

    function _updateCarbonNftData(
        uint256 tokenId,
        string memory serialNumber,
        uint256 carbonAmount
    ) internal {
        NftStatus status = nftList[tokenId].status;
        require(
            status == NftStatus.BatchNFT,
            'Error: this nft is already verified'
        );
        require(
            serialNumberApproved[serialNumber] == false,
            'Serialnumber has already been approved'
        );

        nftList[tokenId].serialNumber = serialNumber;
        nftList[tokenId].carbonAmount = carbonAmount;

 /*       if (!strcmp(uri, nftList[tokenId].uri)) {
            nftList[tokenId].uri = uri;
        }*/

        emit CarbonNftUpdated(tokenId, serialNumber, carbonAmount);
    }

    function unsetSerialNumber(string memory serialNumber)
        external
        onlyVerifier
    {
        serialNumberApproved[serialNumber] = false;
    }
/*  ############################################
        update nft status
    ############################################*/
    function updateStatus(uint256 tokenId, NftStatus newStatus)
        internal
        virtual
    {
        nftList[tokenId].status = newStatus;
        emit CarbonNftStatus(tokenId, newStatus);
    }

/*  ############################################
        nft verify data
    ############################################*/
    function verifyCarbonNft(uint256 tokenId) external virtual onlyVerifier whenNotPaused {
        _verifyCarbonNft(tokenId);
    }
    function _verifyCarbonNft(uint256 tokenId) internal{
        require(
            nftList[tokenId].carbonAmount>0,
            'Error: carbon amount must upper 0'
        );
        NftStatus status = nftList[tokenId].status;
        require(
            status == NftStatus.BatchNFT,
            'Error: this nft is already verified'
        );
        nftList[tokenId].uri= string(abi.encodePacked(baseURI, "/carbonNFT_Verify.json"));
        updateStatus(tokenId, NftStatus.VerifiedNFT);
        string memory CompanyId = nftList[tokenId].CompanyId;
        uint256 NowAmount = CompanyDataList[CompanyId].carbonAmount;
        NowAmount = NowAmount + nftList[tokenId].carbonAmount;
        CompanyDataList[CompanyId].carbonAmount = NowAmount;
    }
/*  ############################################
        nft fraction
    ############################################*/
    function fraction(uint256 tokenId) external virtual {

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );
        NftStatus status = nftList[tokenId].status;
        require(
            status == NftStatus.VerifiedNFT,
            'Error: nft need verified or has already retirement!'
        );
        nftList[tokenId].status = NftStatus.FractionNFT;
        transferFrom(
            _msgSender(), 
            contractRegistry, 
            tokenId);
        emit CarbonNftFraction(tokenId,nftList[tokenId].carbonAmount);
    }
/*  ############################################
        nft transfer
    ############################################*/
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );
        safeTransferFrom(from, to, tokenId, '0x00');
    }
/*  ############################################
        add reply
    ############################################*/
    function addReply(uint256 tokenId, string memory reply) public virtual {
        require(
            hasRole(VERIFIER_ROLE, _msgSender()) ||
                _msgSender() == ownerOf(tokenId) ||
                _msgSender() == owner(),
            'Error: Only the nft owner, contract owner and verifiers can reply'
        );
        require(_exists(tokenId), 'Error: NO this token exist!!');
        nftList[tokenId].reply.push() = reply;
        nftList[tokenId].replyOwner.push() = _msgSender();
        emit NftReply(tokenId,_msgSender(),reply);
    }
/*  ############################################
        nft retirement
    ############################################*/
    function Retired(uint256 tokenId) external virtual returns(bool){
        require(_msgSender() == ownerOf(tokenId),'Error: you do not have this token');
        NftStatus status = nftList[tokenId].status;
        require(
            status == NftStatus.VerifiedNFT,
            'Error: nft need verified or has already retirement / fraction!'
        );
        bool SuccessRetire = IRetirementContract(iMRCRetirementAddress)
            .NFTRetirement(_msgSender(),tokenId, nftList[tokenId].carbonAmount);
        nftList[tokenId].status = NftStatus.RetirementNFT;
        if(SuccessRetire==true){
            return true;
        }
        else{
            return false;
        }
    }
/*  ############################################
        help function
    ############################################*/
    function help() external view virtual returns(string memory){
        return "";
    }
    function totalSupply() public view override returns (uint256) {
        return CarbonNftMaxSupply;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return nftList[tokenId].uri;
    }
    function getCompanyCarbonUsed(string memory CompanyId)
        external
        view
        virtual
        returns(uint256 carbonAmount)
    {
        return CompanyDataList[CompanyId].carbonAmount;
    }
    function getCarbonNftStatus(uint256 tokenId)
        external
        view
        virtual
        override
        returns (NftStatus)
    {
        return nftList[tokenId].status;
    }

    function getCarbonNFTData(uint256 tokenId)
        external
        view
        virtual
        override
        returns (
            uint256,
            NftStatus
        )
    {
        return (
            nftList[tokenId].carbonAmount,
            nftList[tokenId].status
        );
    }

    function getReply(uint256 tokenId)
        external
        view
        virtual
        returns (string[] memory, address[] memory)
    {
        return (nftList[tokenId].reply, nftList[tokenId].replyOwner);
    }

    function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
}
