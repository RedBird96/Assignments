// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenSwap.sol";
import "../src/MockToken.sol";

contract TokenSwapTest is Test {
    TokenSwap swap;
    MockToken token1;
    MockToken token2;

    address public owner;
    uint256 public rate;
    event Swap(address indexed user, uint256 amountA, uint256 amountB);

    function setUp() public {
        owner = vm.addr(1);

        rate = 20e18;
        vm.startPrank(owner);
        token1 = new MockToken(
            "First Token",
            "FT",
            10000e18
        );
        token2 = new MockToken(
            "Second Token",
            "ST",
            10000e18
        );
        swap = new TokenSwap(
            address(token1),
            address(token2),
            rate
        );
        vm.stopPrank();
    }

    function testDeployment() public {
        assertEq(swap.tokenA(), address(token1));
        assertEq(swap.tokenB(), address(token2));
        assertEq(swap.exchangeRate(), rate);
    }

    function testSetExchangeRate(uint256 _rate) public {
        vm.prank(owner);
        if (_rate == 0) {
            vm.expectRevert("Rate cannot be zero");
            swap.setExchangeRate(_rate);
        } else {
            swap.setExchangeRate(_rate);
            assertEq(swap.exchangeRate(), _rate);
        }
    }

    function testSwapAtoB() public {

        vm.expectRevert("Input amount should be bigger than zero");
        swap.swapAtoB(0);
        
        address user = vm.addr(2);
        uint256 amount = 500e18;
        vm.startPrank(owner);
        token1.mint(user, amount);
        token2.mint(address(swap), amount * rate / 1e18);
        vm.stopPrank();
        vm.startPrank(user);
        token1.approve(address(swap), amount);
        uint256 balance = token2.balanceOf(user);
        assertEq(balance, 0);
        swap.swapAtoB(amount);
        (,uint256 expectBAmount) = swap.calculateSwapAmount(amount, 0);
        assertEq(token2.balanceOf(user), expectBAmount);
        vm.stopPrank();
    }

    function testSwapBtoA() public {

        address user = vm.addr(2);
        uint256 amount = 200e18;
        vm.startPrank(owner);
        token1.mint(address(swap), amount);
        token2.mint(user, amount);
        vm.stopPrank();
        vm.startPrank(user);
        token2.approve(address(swap), amount);
        uint256 balance = token1.balanceOf(user);
        assertEq(balance, 0);
        swap.swapBtoA(amount);
        (uint256 expectAAmount,) = swap.calculateSwapAmount(0, amount);
        assertEq(token1.balanceOf(user), expectAAmount);
        vm.stopPrank();
    }
}