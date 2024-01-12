// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is Ownable{
    using SafeERC20 for IERC20;

    IERC20 public presaleToken;
    uint256 public tokenPrice;
    uint256 public presaleCap;
    uint256 public publicSaleCap;
    uint256 public presaleMinContribution;
    uint256 public presaleMaxContribution;
    uint256 public publicSaleMinContribution;
    uint256 public publicSaleMaxContribution;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public publicSaleDuration;

    uint256 public totalPreSaleAmount;
    uint256 public totalPublicSaleAmount;

    mapping(address => uint256) public presaleContributer;
    mapping(address => uint256) public publicSaleContributer;

    event TokensDistributed(address indexed buyer, uint256 amount, uint256 value);
    event Refund(address indexed contributor, uint256 amount);

    /**
     * @param _token project token address
     * @param _tokenPrice project token price
     * @param _presaleCap presale market cap amount
     * @param _publicSaleCap public sale market cap amount
     * @param _presaleMinContribution minimum amount for pre sale
     * @param _presaleMaxContribution maximum amount for pre sale
     * @param _publicSaleMinContribution minimum amount for public sale
     * @param _publicSaleMaxContribution maximum amount for public sale
     * @param _presaleStartTime pre sale start time
     * @param _presaleDuration pre sale duration
     * @param _publicSaleDuration public sale duration
     */
    constructor(
        address _token,
        uint256 _tokenPrice,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _presaleMinContribution,
        uint256 _presaleMaxContribution,
        uint256 _publicSaleMinContribution,
        uint256 _publicSaleMaxContribution,
        uint256 _presaleStartTime,
        uint256 _presaleDuration,
        uint256 _publicSaleDuration
    ) Ownable (msg.sender) {
        require(_publicSaleDuration != 0 , "Public-sale duration cannot zero");
        require(_tokenPrice != 0, "Token price cannot zero");
        presaleToken = IERC20(_token);
        tokenPrice = _tokenPrice;
        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        presaleMinContribution = _presaleMinContribution;
        presaleMaxContribution = _presaleMaxContribution;
        publicSaleMinContribution = _publicSaleMinContribution;
        publicSaleMaxContribution = _publicSaleMaxContribution;
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleStartTime + _presaleDuration;
        publicSaleDuration = _publicSaleDuration;
        totalPreSaleAmount = 0;
        totalPublicSaleAmount = 0;
    }

    modifier onlyPresalePeriod() {
        require(
            block.timestamp >= presaleStartTime, 
            "Pre-sale has not started"
        );
        require(
            block.timestamp <= presaleEndTime, 
            "Pre-sale has ended"
        );
        _;
    }

    modifier onlyPublicsalePeriod() {
        require(
            block.timestamp > presaleEndTime, 
            "Public-sale has not started"
        );
        require(
            block.timestamp <= presaleEndTime + publicSaleDuration, 
            "Public-sale has ended"
        );
        _;
    }

    modifier validPresaleAmount(uint256 amount, address user) {
        require(
            amount >= presaleMinContribution, 
            "Must bigger than Pre-sale minimum contribution"
        );
        require(
            presaleContributer[user] + amount <= presaleMaxContribution, 
            "Must less than Pre-sale maximum contribution"
        );
        _;
    }

    modifier validPublicsaleAmount(uint256 amount, address user) {
        require(
            amount>= publicSaleMinContribution, 
            "Must bigger than Public-sale minimum contribution"
        );
        require(
            publicSaleContributer[user] + amount <= publicSaleMaxContribution, 
            "Must less than Public-sale maximum contribution"
        );
        _;
    }

    /**
     * @notice Contribute ether and get project token in pre sale duration
     * If user call out of presale period it will revert,
     * If the amount range out of min and max it will revert
     * calculate the token amount = ether * token price
     */
    function contributeToPresale() 
        external 
        payable 
        onlyPresalePeriod 
        validPresaleAmount(msg.value, msg.sender) 
    {
        require(totalPreSaleAmount + msg.value <= presaleCap, "Overflow Pre-sale Cap");
        uint256 tokenBalance = IERC20(presaleToken).balanceOf(address(this));
        //calculate expected project token amount depending on ETH value
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        require(tokenAmount <= tokenBalance, "Project token insufficient");

        presaleContributer[msg.sender] += msg.value;
        //Increase the presale total amount and transfer to user
        totalPreSaleAmount += msg.value;
        IERC20(presaleToken).safeTransfer(msg.sender, tokenAmount);

        emit TokensDistributed(msg.sender, tokenAmount, msg.value);
    }

    /**
     * @notice Contribute ether and get project token in public sale duration
     * calculate the token amount = ether * token price
     * If user call out of publicsale period it will revert,
     * If the amount range out of min and max it will revert
     */
    function contributeToPublicsale() 
        external 
        payable 
        onlyPublicsalePeriod 
        validPublicsaleAmount(msg.value, msg.sender)
    {
        require(totalPublicSaleAmount + msg.value <= publicSaleCap, "Overflow Public-sale Cap");
        uint256 tokenBalance = IERC20(presaleToken).balanceOf(address(this));
        //calculate expected project token amount depending on ETH value
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        require(tokenAmount <= tokenBalance, "Project token insufficient");
        
        publicSaleContributer[msg.sender] += msg.value;
        //Increase the publicsale total amount and transfer to user
        totalPublicSaleAmount += msg.value;
        IERC20(presaleToken).safeTransfer(msg.sender, tokenAmount);

        emit TokensDistributed(msg.sender, tokenAmount, msg.value);
    }

    /**
     * @notice Distribute the project token to address
     * @param recipient address to receive the project token
     * @param amount receive token amount
     */
    function distributeToken(address recipient, uint256 amount) external onlyOwner {
        require(
            IERC20(presaleToken).balanceOf(address(this)) >= amount, 
            "Insufficient token amount"
        );
        presaleToken.safeTransfer(recipient, amount);
    }

    /**
     * @notice Set token price, owner can set price only before starting pre sale
     */
    function setTokenPrice(uint256 price) external onlyOwner {
        require(price != 0, "Price cannot zero");
        require(block.timestamp < presaleStartTime, "Pre-sale has already started");
        tokenPrice = price;
    }

    /**
     * @notice Refund the project token for pre sale contributer
     * If presale is not ended it will revert
     * If total amount of presale less than presaleCap it will revert
     */
    function claimRefundForPresale() external payable {
        require(presaleContributer[msg.sender] != 0, "Not participated in Pre-sale");
        require(block.timestamp > presaleEndTime, "Pre-sale has not ended");
        require(totalPreSaleAmount >= presaleCap, "Cannot refund");
        claimRefund(presaleContributer[msg.sender]);
    }

    /**
     * @notice Refund the project token for public sale contributer
     * If public sale is not ended it will revert
     * If total amount of public sale less than publicSaleCap it will revert
     */
    function claimRefundForpublicsale() external payable {
        require(publicSaleContributer[msg.sender] != 0, "Not participated in Public-sale");
        require(
            block.timestamp > presaleEndTime + publicSaleDuration, "Public-sale has not ended");
        require(totalPublicSaleAmount >= publicSaleCap, "Cannot refund");
        claimRefund(publicSaleContributer[msg.sender]);
    }

    /**
     * @notice Calculate the project token from ether amount
     */
    function calculateTokenAmount(uint256 ethAmount) internal view returns(uint256) {
        return ethAmount * tokenPrice / 1e18;
    }

    /**
     * @notice Refund module to send ether and transferfrom project token from user
     */
    function claimRefund(uint256 amount) internal {
        require(address(this).balance >= amount, "Not enough ether");

        //calculate the project token amount
        uint256 tokenAmount = calculateTokenAmount(amount);
        IERC20(presaleToken).safeTransferFrom(msg.sender, address(this), tokenAmount);

        (bool sent,) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {
        revert("Fallback function not allowed");
    }
}
