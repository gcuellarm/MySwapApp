//SPDX-License-Identifier: LGPL-3.0-only

//Version
pragma solidity ^0.8.24;

import "../src/interfaces/IV2Router02.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapApp{
    using SafeERC20 for IERC20;

    address public V2Router02Address;

    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(address tokenA_, address tokenB_);
    event RemoveLiquidity(address tokenA_, address tokenB_);
    event SwapTokensWithFee(address tokenIn, address tokenOut, uint256 amountAfterFee, uint256 amountOut);

    constructor(address V2Router02Address_){
        V2Router02Address = V2Router02Address_;

    }

    function swapTokens(uint256 amountIn_, uint256 amountOutMin_, address[] memory path_, uint256 deadline_) external{
        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);

        IERC20(path_[0]).approve(V2Router02Address, amountIn_);
        uint[] memory amountOuts = IV2Router02(V2Router02Address).swapExactTokensForTokens(amountIn_, amountOutMin_, path_, msg.sender, deadline_);

        emit SwapTokens(path_[0], path_[path_.length -1], amountIn_, amountOuts[amountOuts.length-1]);
    }


    // Adding liquidity
    function addLiquidityToPool(address tokenA_, address tokenB_, uint256 amountADesired_, uint256 amountBDesired_, uint256 amountAMin_,
    uint256 amountBMin_, uint256 deadline_ ) external{
        IERC20(tokenA_).safeTransferFrom(msg.sender, address(this), amountADesired_);
        IERC20(tokenB_).safeTransferFrom(msg.sender, address(this), amountBDesired_);

        IERC20(tokenA_).approve(V2Router02Address, amountADesired_);
        IERC20(tokenB_).approve(V2Router02Address, amountBDesired_);

        (uint256 amountA, uint256 amountB, uint256 liquidity) =  IV2Router02(V2Router02Address).addLiquidity(tokenA_, tokenB_, amountADesired_, amountBDesired_,
        amountAMin_, amountBMin_, msg.sender, deadline_);

        emit AddLiquidity(tokenA_, tokenB_);
    }

    // Removing Liquidity
    function removeLiquitidyFromPool(address tokenA_, address tokenB_, uint256 liquidity_, uint256 amountAMin_, uint256 amountBMin_, uint256 deadline_) public{
        address pair_ = getPair(tokenA_, tokenB_);

        IERC20(pair_).safeTransferFrom(msg.sender, address(this), liquidity_);
        IERC20(pair_).approve(address(V2Router02Address), liquidity_);

        IV2Router02(V2Router02Address).removeLiquidity(tokenA_, tokenB_, liquidity_, amountAMin_, amountBMin_, address(V2Router02Address), deadline_);
        //revisar el "address(V2Router02Address)" => posible error

        emit RemoveLiquidity(tokenA_, tokenB_);

    }


    //Address of the pair 
    function getPair(address tokenA_, address tokenB_) public view returns (address){
        return IV2Router02(V2Router02Address).getPair(tokenA_, tokenB_);
    }

    
    // Swap Exact Tokens for Tokens with fee
    function swapTokensWithFee(uint256 amountIn_, uint256 amountOutMin_, address[] memory path_, uint256 deadline_, uint256 feePercent_) external{
        uint256 fee = (feePercent_ * amountIn_) / 100;
        uint256 amountAfterFee = amountIn_ - fee;

        require(amountAfterFee > 0, "Insuficient amount after fee");

        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);

        IERC20(path_[0]).approve(V2Router02Address, amountAfterFee);
        uint[] memory amountOuts = IV2Router02(V2Router02Address).swapExactTokensForTokens(amountAfterFee, amountOutMin_, path_, msg.sender, deadline_);

        emit SwapTokensWithFee(path_[0], path_[path_.length -1], amountAfterFee, amountOuts[amountOuts.length-1]);



    }
}