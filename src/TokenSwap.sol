// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
    using SafeERC20 for IERC20;

    address public tokenA;
    address public tokenB;
    uint256 public exchangeRate;

    event Swap(address indexed user, uint256 amountA, uint256 amountB);

    /**
     * @param _tokenA First token address
     * @param _tokenB Second token address
     * @param _exchangeRate Exchange rate
     */
    constructor(
        address _tokenA,
        address _tokenB,
        uint256 _exchangeRate
    ) Ownable(msg.sender) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        exchangeRate = _exchangeRate;
    }

    /**
     * @notice Set the exchange rate callable by only owner
     * @param _rate New exchange rate
     */
    function setExchangeRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate cannot be zero");
        exchangeRate = _rate;
    }

    /**
     * @notice Swap tokenA to tokenB
     * If the contract has not enough tokenB amount it will revert
     * @param _amountA Input amount for swap
     */
    function swapAtoB(uint256 _amountA) external {
        require(_amountA > 0, "Input amount should be bigger than zero");   
        uint256 amountB = _amountA * exchangeRate / 1e18;
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        require(amountB > 0, "Invalid swap amount");
        require(amountB <= balanceB, "Insufficient tokenB balance in the pool");   

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), _amountA);
        IERC20(tokenB).safeTransfer(msg.sender, amountB);

        emit Swap(msg.sender, _amountA, amountB);
    }

    /**
     * @notice Swap tokenB to tokenA
     * If the contract has not enough tokenA amount it will revert
     * @param _amountB Input amount for swap
     */
    function swapBtoA(uint256 _amountB) external {
        require(_amountB > 0, "Input amount should be bigger than zero");   
        uint256 amountA = _amountB / exchangeRate * 1e18;
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        require(amountA > 0, "Invalid swap amount");   
        require(amountA < balanceA, "Insufficient tokenB balance in the pool");   

        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), _amountB);
        IERC20(tokenA).safeTransfer(msg.sender, amountA);

        emit Swap(msg.sender, amountA, _amountB);
    }

    /**
     * @notice calculate the expected token amount
     * Calculate the expected tokenA, tokenB amount
     */
    function calculateSwapAmount(uint256 _amountA, uint256 _amountB)
        external 
        view 
        returns(uint256 expectedAmountA, uint256 expectedAmountB) 
    {
        expectedAmountA = _amountB / exchangeRate * 1e18;
        expectedAmountB = _amountA * exchangeRate / 1e18;
    }

}