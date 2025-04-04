# 🚀MySwapApp

MySwapApp is a decentralized application (dApp) designed to facilitate token swaps on the Ethereum blockchain. Built using Foundry, a high-performance development toolkit for Ethereum applications, MySwapApp aims to provide users with a seamless and efficient token swapping experience.

## Features

- **Decentralized Token Swapping**: Enables users to swap ERC-20 tokens directly from their wallets without relying on centralized exchanges.
- **User-Friendly Interface**: Simplifies the token swapping process with an intuitive and easy-to-navigate interface.
- **Secure Transactions**: Leverages Ethereum's robust security features to ensure safe and transparent transactions.
- **High Performance**: Utilizes Foundry's capabilities to deliver fast and reliable operations.

## Prerequisites

Before setting up MySwapApp, ensure you have the following installed:

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html): The Ethereum application development toolkit.

## Installation

Follow these steps to set up MySwapApp:

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/gcuellarm/MySwapApp.git
   ```

2. **Navigate to the Project Directory**:

   ```bash
   cd MySwapApp
   ```

3. **Install Dependencies**:

   ```bash
   forge install
   ```

## 📄 Smart Contract: `SwapApp.sol`

The `SwapApp` smart contract is a custom wrapper around the Uniswap V2 router (`IV2Router02`) that provides users with a simple interface to swap tokens, add/remove liquidity, and optionally include swap fees that are forwarded to a designated fee receiver address. The contract is written in Solidity and follows secure practices such as reentrancy protection via `ReentrancyGuard` and safe token transfers using `SafeERC20`.

### 🔐 Security Features
- **ReentrancyGuard**: Protects critical external calls against reentrancy attacks.
- **SafeERC20**: Ensures safe and error-checked ERC-20 token operations.

---

### ⚙️ Constructor

```solidity
constructor(address V2Router02Address_, address feeReceiver_)
```

- `V2Router02Address_`: Address of the Uniswap V2 router.
- `feeReceiver_`: Address where fees from `swapTokensWithFee` are sent.

---

### 🔁 `swapTokens(...)`

Swaps an exact amount of input tokens for as many output tokens as possible along a defined path using the Uniswap V2 router.

- Ensures minimum output is respected.
- Requires prior approval of input tokens.
- Emits a `SwapTokens` event.

---

### 💧 `addLiquidityToPool(...)`

Adds liquidity to a Uniswap pool with a given token pair. If any extra tokens are unused in the process, they are refunded to the user.

- Returns actual token amounts used and the liquidity tokens received.
- Emits an `AddLiquidity` event.

---

### 💦 `removeLiquidityFromPool(...)`

Removes liquidity from a token pair pool and returns the underlying tokens to the user.

- Uses the pair address resolved from `getPair(...)`.
- Requires approval of LP tokens.
- Emits a `RemoveLiquidity` event.

---

### 🔍 `getPair(...)`

Returns the address of the pair for a given token pair using the router’s internal reference.

---

### 💸 `swapTokensWithFee(...)`

Swaps tokens similarly to `swapTokens(...)`, but deducts a customizable fee (expressed in basis points, e.g., `100 = 1%`) from the input amount before performing the swap.

- The fee is transferred to the `feeReceiver`.
- Emits a `SwapTokensWithFee` event.

---

### 🧾 Events

- `SwapTokens(tokenIn, tokenOut, amountIn, amountOut)`
- `SwapTokensWithFee(tokenIn, tokenOut, amountAfterFee, amountOut)`
- `AddLiquidity(tokenA, tokenB)`
- `RemoveLiquidity(tokenA, tokenB)`

## 🧪 Tests: `SwapAppTest.t.sol`

This test contract uses **Foundry**'s `forge-std/Test.sol` library to test the `SwapApp` smart contract on Arbitrum Mainnet. It covers all the critical features, edge cases, and reverts for swaps, liquidity operations, and fee-based interactions.

### 📌 Notes
Some of the test may fail initially due to the way they were executed (arbitrum fork), some of the users may not have funds available. Choose other users or prepare some mocks and change it to local environment to make it work properly.

### 🔧 Setup

```solidity
SwapApp app;
address uniswapV2SwapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
address user = 0xfAf87e196A29969094bE35DfB0Ab9d0b8518dB84; // USDT holder on Arbitrum
address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
address feeReceiver = vm.addr(3);
```

---

### ✅ Deployment

- `testHasBeenDeployedCorrectly()`  
  ✅ Verifies the contract is initialized with the correct router address.

---

### 🔁 Swapping Tokens

- `testShouldRevertIfPathLengthInsuficient()`  
  🔥 Reverts if path length < 2.

- `testShouldRevertIfNotEnoughTokensApproved()`  
  🔥 Reverts if allowance is insufficient.

- `testSwapTokensCorrectly()`  
  ✅ Successful token swap from USDT → DAI.

---

### 💧 Adding Liquidity

- `testLiquidityShouldRevertIfTokensAreTheSame()`  
  🔥 Reverts if tokenA == tokenB.

- `testShouldRevertIfDeadlineAlreadyExpired()`  
  🔥 Reverts if deadline is in the past.

- `testShouldRevertIfAmountDesiredIsZero()`  
  🔥 Reverts if either token desired is 0.

- `testShouldRevertIfAmountMinsExceedDesired()`  
  🔥 Reverts if min amounts > desired amounts.

- `testAddLiquidityCorrectly()`  
  ✅ Successfully adds liquidity to a token pair.

---

### 💦 Removing Liquidity

- `testShouldRevertIfAddressZero()`  
  🔥 Reverts if one of the token addresses is `address(0)`.

- `testShouldRevertIfLiquidityIsZero()`  
  🔥 Reverts if liquidity parameter is 0.

- `testRemoveLiquidityCorrectly()`  
  ✅ Successfully removes liquidity and receives both tokens back.

---

### 💸 Swapping With Fees

- `testShouldRevertWithInsuficientPathFee()`  
  🔥 Reverts if path is invalid.

- `testSwapTokensWithFeeCorrectly()`  
  ✅ Successfully swaps tokens with fee:
  - Fee goes to `feeReceiver`.
  - Output respects `amountOutMin`.


Refer to the [Cast Documentation](https://book.getfoundry.sh/cast/intro) for a list of available subcommands and usage examples.

## Contributing

We welcome contributions to MySwapApp! To contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/YourFeature`).
3. Commit your changes (`git commit -m 'Add your feature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Open a pull request.

Please ensure your code adheres to the project's coding standards and includes appropriate tests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Foundry](https://book.getfoundry.sh/): For providing a robust toolkit for Ethereum application development.
- The Ethereum community: For continuous support and development of decentralized technologies.

---
