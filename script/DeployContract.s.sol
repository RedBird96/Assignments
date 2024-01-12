// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseDeployer.s.sol";
import "../src/MultiSigWallet.sol";
import "../src/TokenSale.sol";
import "../src/TokenSwap.sol";
import "../src/Voting.sol";

contract DeployContract is BaseDeployer {
    
    MultiSigWallet public wallet;
    TokenSale public tokenSale;
    TokenSwap public tokenSwap;
    Voting public voting;

    address public projectToken;
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

    address public tokenASwap;
    address public tokenBSwap;
    uint256 public rateSwap;

    uint256 public requireApproval;
    address public owner1;
    address public owner2;
    function setUp() public {
    }
    
    function deployTest() external setEnvDeploy(Cycle.Dev) {
        createSelectFork(Chains.LocalSepolia);
        deployTokenSale();
        deployTokenSwap();
        deployVoting();
        deployMultiSigWallet();
    }

    function deploySelectedChains(
        Chains[] calldata deployForks,
        Cycle cycle
    ) external setEnvDeploy(cycle){
        for (uint256 i; i < deployForks.length; ) {
            
            createSelectFork(deployForks[i]);
            deployTokenSale();
            deployTokenSwap();
            deployVoting();
            deployMultiSigWallet();
        
            unchecked {
                ++i;
            }
        }
    }

    function deployTokenSale() private broadcast(_deployerPrivateKey) {
        projectToken = 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06;
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
            projectToken,
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
    }

    function deployTokenSwap() private broadcast(_deployerPrivateKey) {
        
        rateSwap = 15e18;
        tokenSwap = new TokenSwap(
            tokenASwap,
            tokenBSwap,
            rateSwap
        );
    }

    function deployVoting() private broadcast(_deployerPrivateKey) {
        voting = new Voting();
    }

    function deployMultiSigWallet() private broadcast(_deployerPrivateKey) {
        
        requireApproval = 2;
        address[] memory multiOwner = new address[](2);
        wallet = new MultiSigWallet(
            multiOwner,
            requireApproval
        );
    }
}
