//SPDX-License-Identifier: LGPL-3.0-only

//Version
pragma solidity ^0.8.24;

import "../src/interfaces/IV2Router02.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract SwapApp is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public V2Router02Address;
    address public feeReceiver; // could be the admin or whoever it is decided to obtain the fee

    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(address tokenA_, address tokenB_);
    event RemoveLiquidity(address tokenA_, address tokenB_);
    event SwapTokensWithFee(address tokenIn, address tokenOut, uint256 amountAfterFee, uint256 amountOut);

    constructor(address V2Router02Address_, address feeReceiver_) {
        V2Router02Address = V2Router02Address_;
        feeReceiver = feeReceiver_;
    }

    /**
     * @dev Swaps an exact amount of input tokens for as many output tokens as possible
     * along the specified path using the V2 Router. The caller must have approved this
     * contract to spend the input tokens.
     *
     * Reverts if the path length is less than 2 or if the output amount is less than
     * the specified minimum.
     *
     * Emits a {SwapTokens} event.
     *
     * @param amountIn_ The amount of input tokens to swap.
     * @param amountOutMin_ The minimum amount of output tokens to receive.
     * @param path_ An array of token addresses representing the swap path (e.g., [tokenIn, tokenOut]).
     * @param deadline_ The timestamp by which the transaction must be mined.
     */
    function swapTokens(uint256 amountIn_, uint256 amountOutMin_, address[] memory path_, uint256 deadline_)
        external
        nonReentrant
    {
        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
        require(path_.length >= 2, "Invalid path length");

        IERC20(path_[0]).approve(V2Router02Address, amountIn_);
        uint256[] memory amountOuts = IV2Router02(V2Router02Address).swapExactTokensForTokens(
            amountIn_, amountOutMin_, path_, msg.sender, deadline_
        );

        require(amountOuts[amountOuts.length - 1] >= amountOutMin_, "Insufficient output amount");

        emit SwapTokens(path_[0], path_[path_.length - 1], amountIn_, amountOuts[amountOuts.length - 1]);
    }

    /**
     * @dev Adds liquidity to a token pair pool using the V2 Router. The caller must have
     * approved this contract to spend the desired amounts of both tokens. Excess tokens
     * not used by the router are returned to the caller.
     *
     * Emits an {AddLiquidity} event.
     *
     * @param tokenA_ The address of the first token in the pair.
     * @param tokenB_ The address of the second token in the pair.
     * @param amountADesired_ The desired amount of tokenA to add as liquidity.
     * @param amountBDesired_ The desired amount of tokenB to add as liquidity.
     * @param amountAMin_ The minimum amount of tokenA to add (slippage protection).
     * @param amountBMin_ The minimum amount of tokenB to add (slippage protection).
     * @param deadline_ The timestamp by which the transaction must be mined.
     */
    function addLiquidityToPool(
        address tokenA_,
        address tokenB_,
        uint256 amountADesired_,
        uint256 amountBDesired_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        uint256 deadline_
    ) external nonReentrant returns (uint256, uint256, uint256) {
        require(tokenA_ != tokenB_, "Tokens must be different");
        require(deadline_ >= block.timestamp, "Deadline has expired");
        require(amountADesired_ > 0 && amountBDesired_ > 0, "Amounts must be greater than zero");
        require(
            amountAMin_ <= amountADesired_ && amountBMin_ <= amountBDesired_, "Minimum amounts exceed desired amounts"
        );

        IERC20(tokenA_).safeTransferFrom(msg.sender, address(this), amountADesired_);
        IERC20(tokenB_).safeTransferFrom(msg.sender, address(this), amountBDesired_);

        IERC20(tokenA_).approve(V2Router02Address, amountADesired_);
        IERC20(tokenB_).approve(V2Router02Address, amountBDesired_);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = IV2Router02(V2Router02Address).addLiquidity(
            tokenA_, tokenB_, amountADesired_, amountBDesired_, amountAMin_, amountBMin_, msg.sender, deadline_
        );

        if (amountADesired_ > amountA) {
            IERC20(tokenA_).safeTransfer(msg.sender, amountADesired_ - amountA);
        }
        if (amountBDesired_ > amountB) {
            IERC20(tokenB_).safeTransfer(msg.sender, amountBDesired_ - amountB);
        }

        emit AddLiquidity(tokenA_, tokenB_);

        return (amountA, amountB, liquidity);
    }

    /**
     * @dev Removes liquidity from a token pair pool using the V2 Router. The caller must
     * have approved this contract to spend the liquidity tokens. The withdrawn tokens
     * are sent directly to the caller.
     *
     * Emits a {RemoveLiquidity} event.
     *
     * @param tokenA_ The address of the first token in the pair.
     * @param tokenB_ The address of the second token in the pair.
     * @param liquidity_ The amount of liquidity tokens to remove.
     * @param amountAMin_ The minimum amount of tokenA to receive (slippage protection).
     * @param amountBMin_ The minimum amount of tokenB to receive (slippage protection).
     * @param deadline_ The timestamp by which the transaction must be mined.
     */
    function removeLiquidityFromPool(
        address tokenA_,
        address tokenB_,
        uint256 liquidity_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        uint256 deadline_
    ) public nonReentrant {
        require(tokenA_ != address(0) && tokenB_ != address(0), "Invalid token addresses");
        require(liquidity_ > 0, "Liquidity must be greater than zero");

        address pair_ = getPair(tokenA_, tokenB_);

        IERC20(pair_).safeTransferFrom(msg.sender, address(this), liquidity_);
        IERC20(pair_).approve(address(V2Router02Address), liquidity_);

        IV2Router02(V2Router02Address).removeLiquidity(
            tokenA_, tokenB_, liquidity_, amountAMin_, amountBMin_, msg.sender, deadline_
        );
        //revisar el "address(V2Router02Address)" => posible error

        emit RemoveLiquidity(tokenA_, tokenB_);
    }

    /**
     * @dev Returns the address of the liquidity pair for the specified token pair
     * as provided by the V2 Router.
     *
     * @param tokenA_ The address of the first token in the pair.
     * @param tokenB_ The address of the second token in the pair.
     * @return The address of the liquidity pair contract.
     */
    function getPair(address tokenA_, address tokenB_) public view returns (address) {
        return IV2Router02(V2Router02Address).getPair(tokenA_, tokenB_);
    }

    /**
     * @dev Swaps an exact amount of input tokens for as many output tokens as possible
     * along the specified path using the V2 Router, deducting a fee from the input amount.
     * The caller must have approved this contract to spend the input tokens. The fee is
     * transferred to the feeReceiver address.
     *
     * Reverts if the path length is less than 2, if the amount after fee is zero, or if
     * the output amount is less than the specified minimum.
     *
     * Emits a {SwapTokensWithFee} event.
     *
     * @param amountIn_ The amount of input tokens to swap.
     * @param amountOutMin_ The minimum amount of output tokens to receive.
     * @param path_ An array of token addresses representing the swap path (e.g., [tokenIn, tokenOut]).
     * @param deadline_ The timestamp by which the transaction must be mined.
     * @param feePercent_ The fee percentage to deduct from the input amount (in basis points, where 10000 = 100%).
     */
    function swapTokensWithFee(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        uint256 deadline_,
        uint256 feePercent_
    ) external nonReentrant {
        uint256 fee = (feePercent_ * amountIn_) / 10000; // 10000 = 100% | Dividing by 10000 the fee can be 0.01%
        uint256 amountAfterFee = amountIn_ - fee;

        require(path_.length >= 2, "Invalid path length");
        require(amountAfterFee > 0, "Insuficient amount after fee");

        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);

        IERC20(path_[0]).approve(V2Router02Address, amountIn_);
        uint256[] memory amountOuts = IV2Router02(V2Router02Address).swapExactTokensForTokens(
            amountAfterFee, amountOutMin_, path_, msg.sender, deadline_
        );

        // Check the a<mount received fits the minimum expected
        require(amountOuts[amountOuts.length - 1] >= amountOutMin_, "Insufficient output amount");

        IERC20(path_[0]).safeTransfer(feeReceiver, fee); // Transfer the fee

        emit SwapTokensWithFee(path_[0], path_[path_.length - 1], amountAfterFee, amountOuts[amountOuts.length - 1]);
    }
}
