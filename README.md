## Assignment Tasks

**There are 4 smart contracts in this project**

Included contract:
-   **TokenSale**: Token Sale Smart Contract - src/TokenSale.sol
-   **TokenSwap**: Token Swap Smart Contract - src/TokenSwap.sol
-   **Voting**: Decentralized Voting System - src/Voting.sol
-   **MultiSigWallet**: Multi-Signature Wallet - src/MultiSigWallet.sol
-   **MockToken**: Mock token smart contract for testing support - src/MockToken.sol

### TokenSale
This is a smart contract for token sale. There are two types of sale private sale and public sale.
Each of the sale has `minimum`, `maximum`, `capacity`, `period`. And user can participated in public sale once the private sale has ended.<br/>
If the total amount does not reach `capacity`, user can refund his ETH amount and send back project Token. Before starting the presale owner can set the token price. User can refund only the presale or public sale ended.<br/>
These are main methods:<br/>
- contributeToPresale()
- contributeToPublicsale()
- claimRefundForPresale()
- claimRefundForpublicsale()


### TokenSwap
This is a smart contract for token swap. User can swap from tokenA to tokenB using fixed `exchangeRate`. Only owner can change the `exchangeRate` anytime.<br/>
These are main methods:<br/>
- swapAtoB()
- swapBtoA()

### Voting
This is a smart contract for decentralized voting system. Voters can vote any candidate.<br/>
Any user can register himself as voter and only owner can add candidate on this system. Voter can vote after system start. The candidate who get most votes win.<br/>
These are main methods:<br/>
- registerVoter()
- addCandidate()
- vote()
- getElectionResult()

### MultiSigWallet
This is a smart contract of multi-signature wallet. There are several owners can approve and execute one transaction. And the transaction can only execute when approved more than `requiredApprovals`.<br/> One owner can approve only once and executed transaction cannot approve, cancel again.<br/>
These are main methods:<br/>
- submitTransaction()
- approveTransaction()
- executeTransaction()
- cancelTransaction()


## Test contracts

- test/TokenSale.t.sol - Test contract for testing TokenSale
- test/TokenSwap.t.sol - Test contract for testing TokenSwap
- test/Voting.t.sol - Test contract for testing Voting
- test/MultiSigWallet.t.sol - Test contract for testing MultiSigWallet

```shell
$ forge test
```

## Deploy
- script/BaseDeployer.s.sol - Deploy basic module contract
- script/DeployContract.s.sol - Deploy contract for all

To deploy the contract you have to set `DEPLOYER_KEY` and RPC ruls on env file. <br/>
To deploy on sepolia you can call `deployTest` and to deploy on ethereum or arbitrum mainnet you can call `deploySelectedChains`. <br/>

```shell
$ forge script DeployContract -s "deployTest()" --force --broadcast --verify
```


### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
