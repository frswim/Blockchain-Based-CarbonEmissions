// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ICarbonNft.sol";
import "./IContract.sol";
import "./IiMRCTokenFactory.sol";
import "./CarbonTokenStorage.sol";
import "./CarbonNftStatus.sol";
import "./IRetirementContract.sol";

contract iMRCToken is
    Initializable, 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    PausableUpgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable,
    IERC721Receiver,
    CarbonTokenStorage
{
    //constant------------------
    string public constant VERSION = "1.0";
    uint256 public constant VERSION_RELEASE_CANDIDATE = 1;
    uint256 public CarbonTokenMaxSupply;
    //event---------------------
    event Fraction(address receiver,uint256 amount);
    event Retired(address sender, uint256 amount);
    event FeePaid(address bridger, uint256 fees);
    event FeeBurnt(address bridger, uint256 fees);
    //constructor----------------
    constructor() {
        _disableInitializers();
    }
    //initialize-----------------
    function initialize() initializer public{
        __ERC20_init("GiM-4.2_CarbonToken", "GiM-CT");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        CarbonTokenMaxSupply=1000000;
       // projectVintageTokenId = _projectVintageTokenId;
       // contractRegistry = _contractRegistry;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /*function bridgeBurn(address account, uint256 amount)
        external
        virtual
        whenNotPaused
        onlyBridges
    {
        _burn(account, amount);
    }

    function bridgeMint(address account, uint256 amount)
        external
        virtual
        whenNotPaused
        onlyBridges
    {
        _mint(account, amount);
    }*/

    // ----------------------------------------
    //       Admin functions
    // ----------------------------------------
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

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner() {
        CarbonTokenMaxSupply = _newMaxSupply;
    }

    /*function defractionalize(uint256 tokenId)
        external
        whenNotPaused
        onlyOwner
    {
        address batchNFT = ITokenContract(contractRegistry).iMRCNFTAddress();

        // Fetch and burn amount of the NFT to be defractionalized
        (, uint256 carbonAmount, ) = ICarbonOffsetBatches(batchNFT).getBatchNFTData(
            tokenId
        );
        _burn(msg.sender, carbonAmount);

        // Transfer batch NFT to sender
        IERC721(batchNFT).transferFrom(address(this), msg.sender, tokenId);
    }*/

    // ----------------------------------------
    //       Permissionless functions
    // ----------------------------------------

    function onERC721Received(
        address ,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external virtual override whenNotPaused returns (bytes4) {

        require(
            checkWhiteListed(contractRegistry),
            'Error: NFT not from whitelisted contract'
        );

        (uint256 carbonAmount,NftStatus status) = ICarbonNft(contractRegistry).getCarbonNFTData(tokenId);
        /*require(
            gotVintageTokenId == projectVintageTokenId,
            'Error: non-matching NFT'
        );*/
        require(
            status == NftStatus.FractionNFT,
            'NFT not yet pending Fraction'
        );

        minterToId[from] = tokenId;
        carbonAmount = carbonAmount * 10**decimals();

        require(
            getRemaining() >= carbonAmount,
            'Error: carbonAmount in batch is higher than total'
        );
        uint256 newCount=TokenCounter;
        unchecked{
            newCount=newCount+carbonAmount;
        }
        TokenCounter=newCount;
        _mint(from, carbonAmount);
        emit Fraction(from, carbonAmount);
        return this.onERC721Received.selector;
    }

    function checkWhiteListed(address collection)
        internal
        view
        virtual
        returns (bool)
    {
        if (
            //collection ==ITokenContract(contractRegistry).iMRCNFTAddress()
            collection==contractRegistry
        ) {
            return true;
        } 
        else {
            return false;
        }
    }

    function getRemaining() public view returns (uint256 remaining) {
        uint256 cap = CarbonTokenMaxSupply* 10**decimals();
        remaining = cap - TokenCounter;
    }

    function Retire(uint256 amount)
        external
        virtual
        whenNotPaused
    {
        uint256 decimals = this.decimals();
        decimals=10**decimals;
        amount=amount*decimals;
        require(balanceOf(_msgSender())>=amount,'Error: no more token');
        address to = msg.sender;
        _burn(to, amount);
        uint256 used = amount;
        getRetiredAmount[to].retireAmount=used;
        IRetirementContract(iMRCRetirementAddress).TokenRetirement(to,amount);
        //_retire(_msgSender(), amount);
    }

    /*function retireFrom(address account, uint256 amount)
        external
        virtual
        whenNotPaused
        //returns (uint256 retirementEventId)
    {
        _spendAllowance(account, msg.sender, amount);
        //retirementEventId = _retire(account, amount);
    }*/

    function _retire(address account, uint256  amount)
        internal
        virtual
        //returns(bool)
    {
        account = _msgSender();
        //_burn(account, amount);
        getRetiredAmount[account].retireAmount=100*(10**decimals());
        //bool SuccessRetire = IRetirementContract(iMRCRetirementAddress).TokenRetirement(amount);
        IRetirementContract(iMRCRetirementAddress).TokenRetirement(account,amount);
        /*if(SuccessRetire==true){
            emit Retired(account, amount);
            return true;
        }
        else{
            return false;
        }*/
    }


    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        validDestination(recipient)
        whenNotPaused
        returns (bool)
    {
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        validDestination(recipient)
        whenNotPaused
        returns (bool)
    {
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return CarbonTokenMaxSupply;
    }

    function getCarbonTokenRetirement(address to) external view returns (uint256){
        return getRetiredAmount[to].retireAmount;
    }

    function getdemicals() external view returns (uint256){
        return this.decimals();
    }
}