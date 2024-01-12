// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenSale.sol";
import "../src/MockToken.sol";

contract TokenSaleTest is Test {

    TokenSale public tokenSale;
    MockToken public mockToken;
    
    address public owner;
    uint256 public tokenPrice;
    uint256 public presaleCap;
    uint256 public publicsaleCap;
    uint256 public presaleMin;
    uint256 public presaleMax;
    uint256 public publicsaleMin;
    uint256 public publicsaleMax;
    uint256 public presaleStart;
    uint256 public presalePeriod;
    uint256 public publicsalePeriod;

    event TokensDistributed(address indexed buyer, uint256 amount, uint256 value);
    event Refund(address indexed contributor, uint256 amount);

    function setUp() public {

        owner = vm.addr(1);

        vm.startPrank(owner);
        mockToken = new MockToken(
            "Project Token",
            "PT",
            100000000e18
        );

        tokenPrice = 10e18;
        presaleCap = 1000e18;
        publicsaleCap = 2000e18;
        presaleMin = 100e18;
        presaleMax = 300e18;
        publicsaleMin = 200e18;
        publicsaleMax = 600e18;
        presaleStart = block.timestamp + 1 hours;
        presalePeriod = 10 minutes;
        publicsalePeriod = 30 minutes;

        tokenSale = new TokenSale(
            address(mockToken),
            tokenPrice,
            presaleCap,
            publicsaleCap,
            presaleMin,
            presaleMax,
            publicsaleMin,
            publicsaleMax,
            presaleStart,
            presalePeriod,
            publicsalePeriod
        );
        vm.stopPrank();
    }

    function testDeployment() public {
        assertEq(tokenSale.tokenPrice(), tokenPrice);
        assertEq(tokenSale.presaleCap(), presaleCap);
        assertEq(tokenSale.publicSaleCap(), publicsaleCap);
        assertEq(tokenSale.presaleMinContribution(), presaleMin);
        assertEq(tokenSale.presaleMaxContribution(), presaleMax);
        assertEq(tokenSale.publicSaleMinContribution(), publicsaleMin);
        assertEq(tokenSale.publicSaleMaxContribution(), publicsaleMax);
        assertEq(tokenSale.presaleStartTime(), presaleStart);
        assertEq(tokenSale.presaleEndTime(), presaleStart+presalePeriod);
        assertEq(tokenSale.publicSaleDuration(), publicsalePeriod);
    }

    function testSetTokenPrice(uint256 _price) public {
        address user1 = vm.addr(2);
        vm.deal(user1, 10e18); 
        vm.prank(user1);
        vm.expectRevert();
        tokenSale.setTokenPrice(_price);
        
        vm.prank(owner);
        if (_price == 0) {
            vm.expectRevert("Price cannot zero");
            tokenSale.setTokenPrice(_price);    
        } else {
            tokenSale.setTokenPrice(_price);
            assertEq(tokenSale.tokenPrice(), _price);
        }
    }
    function testContributeToPresale() public {
        address user1 = vm.addr(2);
        address user2 = vm.addr(3);
        address user3 = vm.addr(4);
        address user4 = vm.addr(5);
        vm.deal(user1, 1000e18);
        vm.deal(user2, 1000e18);
        vm.deal(user3, 1000e18);
        vm.deal(user4, 1000e18);

        vm.expectRevert("Pre-sale has not started");
        tokenSale.contributeToPresale();

        vm.warp(presaleStart);
        vm.expectRevert("Must bigger than Pre-sale minimum contribution");
        tokenSale.contributeToPresale();

        vm.warp(presaleStart + presalePeriod + 1);
        vm.expectRevert("Pre-sale has ended");
        tokenSale.contributeToPresale();

        vm.warp(presaleStart);
        vm.expectRevert("Must bigger than Pre-sale minimum contribution");
        tokenSale.contributeToPresale{value:1}();

        vm.startPrank(user1);
        vm.expectRevert("Project token insufficient");
        tokenSale.contributeToPresale{value:presaleMin}();

        vm.expectRevert("Must less than Pre-sale maximum contribution");
        tokenSale.contributeToPresale{value:presaleMax + 1}();
        vm.stopPrank();

        vm.prank(owner);
        mockToken.transfer(address(tokenSale), (presaleCap + publicsaleCap) * tokenPrice / 1e18);

        vm.startPrank(user1);
        vm.expectEmit();
        emit TokensDistributed(address(user1), presaleMin * tokenPrice / 1e18, presaleMin);
        tokenSale.contributeToPresale{value:presaleMin}();

        vm.expectEmit();
        emit TokensDistributed(address(user1), presaleMin * tokenPrice / 1e18, presaleMin);
        tokenSale.contributeToPresale{value:presaleMin}();       
        
        vm.expectRevert("Must less than Pre-sale maximum contribution");
        tokenSale.contributeToPresale{value:presaleMax}();   
        assertEq(mockToken.balanceOf(user1), 2 * presaleMin * tokenPrice / 1e18) ;  
        vm.stopPrank();

        vm.prank(user2);
        tokenSale.contributeToPresale{value:presaleMax}();     
        assertEq(mockToken.balanceOf(user2), presaleMax * tokenPrice / 1e18) ;  
        vm.prank(user3);
        tokenSale.contributeToPresale{value:presaleMax}();  
        assertEq(mockToken.balanceOf(user3), presaleMax * tokenPrice / 1e18) ;  

        vm.prank(user4);
        vm.expectRevert("Overflow Pre-sale Cap");
        tokenSale.contributeToPresale{value:presaleMax}();  
    }

    function testContributeToPublicSale() public {
        address user1 = vm.addr(2);
        address user2 = vm.addr(3);
        address user3 = vm.addr(4);
        address user4 = vm.addr(5);
        vm.deal(user1, 1000e18);
        vm.deal(user2, 1000e18);
        vm.deal(user3, 1000e18);
        vm.deal(user4, 1000e18);

        vm.expectRevert("Public-sale has not started");
        tokenSale.contributeToPublicsale();

        vm.warp(presaleStart);
        vm.expectRevert("Public-sale has not started");
        tokenSale.contributeToPublicsale();

        vm.warp(presaleStart + presalePeriod + publicsalePeriod + 1);
        vm.expectRevert("Public-sale has ended");
        tokenSale.contributeToPublicsale();

        vm.startPrank(user1);
        vm.warp(presaleStart + presalePeriod + 1);
        vm.expectRevert("Must bigger than Public-sale minimum contribution");
        tokenSale.contributeToPublicsale{value:1}();

        vm.expectRevert("Must less than Public-sale maximum contribution");
        tokenSale.contributeToPublicsale{value:publicsaleMax + 1}();
        vm.stopPrank();

        vm.expectRevert("Project token insufficient");
        tokenSale.contributeToPublicsale{value:publicsaleMin}();

        vm.prank(owner);
        mockToken.transfer(address(tokenSale), (presaleCap + publicsaleCap) * tokenPrice / 1e18);

        vm.startPrank(user1);
        vm.expectEmit();
        emit TokensDistributed(address(user1), publicsaleMin * tokenPrice / 1e18, publicsaleMin);
        tokenSale.contributeToPublicsale{value:publicsaleMin}();

        vm.expectEmit();
        emit TokensDistributed(address(user1), publicsaleMin * tokenPrice / 1e18, publicsaleMin);
        tokenSale.contributeToPublicsale{value:publicsaleMin}();    
        assertEq(mockToken.balanceOf(user1), 2 * publicsaleMin * tokenPrice / 1e18) ;

        vm.stopPrank();

        vm.prank(user2);
        tokenSale.contributeToPublicsale{value:publicsaleMax}();   
        assertEq(mockToken.balanceOf(user2), publicsaleMax * tokenPrice / 1e18) ;   
    
        vm.prank(user3);
        tokenSale.contributeToPublicsale{value:publicsaleMax}();    
        assertEq(mockToken.balanceOf(user3), publicsaleMax * tokenPrice / 1e18) ;  

        vm.prank(user4);
        vm.expectRevert("Overflow Public-sale Cap");
        tokenSale.contributeToPublicsale{value:publicsaleMax}();    
    }

    function testClaimRefundForPresale() public {
        address user1 = vm.addr(2);
        vm.deal(user1, 1000e18);

        vm.expectRevert("Not participated in Pre-sale");
        tokenSale.claimRefundForPresale();

        vm.prank(owner);
        mockToken.transfer(address(tokenSale), (presaleCap + publicsaleCap) * tokenPrice / 1e18);

        vm.startPrank(user1);
        vm.warp(presaleStart);
        tokenSale.contributeToPresale{value:presaleMin}();

        vm.warp(presaleStart + presalePeriod + 1);
        vm.expectRevert("Cannot refund");
        tokenSale.claimRefundForPresale();
        vm.stopPrank();
        
        vm.warp(presaleStart);
        for(uint8 index = 3; index < 6; index ++) {
            address user2 = vm.addr(index);
            vm.deal(user2, 1000e18);
            vm.prank(user2);
            tokenSale.contributeToPresale{value:presaleMax}();
        }
        
        vm.startPrank(user1);
        vm.warp(presaleStart + presalePeriod + 1);
        uint256 balance = mockToken.balanceOf(user1);
        mockToken.approve(address(tokenSale), balance);
        tokenSale.claimRefundForPresale();
        uint256 afterBalance = mockToken.balanceOf(user1);
        assertEq(afterBalance, 0);
        vm.stopPrank();

    }

    function testClaimRefundForPublicsale() public {
        address user1 = vm.addr(2);
        vm.deal(user1, 1000e18);

        vm.expectRevert("Not participated in Public-sale");
        tokenSale.claimRefundForpublicsale();

        vm.prank(owner);
        mockToken.transfer(address(tokenSale), (presaleCap + publicsaleCap) * tokenPrice / 1e18);

        vm.startPrank(user1);
        vm.warp(presaleStart + presalePeriod + 1);
        tokenSale.contributeToPublicsale{value:publicsaleMin}();

        vm.expectRevert("Public-sale has not ended");
        tokenSale.claimRefundForpublicsale();
        vm.stopPrank();
        
        vm.prank(user1);
        vm.expectRevert("Cannot refund");
        vm.warp(presaleStart + presalePeriod + publicsalePeriod + 1);
        tokenSale.claimRefundForpublicsale();

        vm.warp(presaleStart + presalePeriod + 1);
        for(uint8 index = 3; index < 6; index ++) {
            address user2 = vm.addr(index);
            vm.deal(user2, 1000e18);
            vm.prank(user2);
            tokenSale.contributeToPublicsale{value:publicsaleMax}();
        }
        
        vm.startPrank(user1);
        vm.warp(presaleStart + presalePeriod + publicsalePeriod + 1);
        uint256 balance = mockToken.balanceOf(user1);
        mockToken.approve(address(tokenSale), balance);
        tokenSale.claimRefundForpublicsale();
        uint256 afterBalance = mockToken.balanceOf(user1);
        assertEq(afterBalance, 0);
        vm.stopPrank();


    }
}
