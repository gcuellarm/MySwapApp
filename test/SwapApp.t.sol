//SPDX-License-Identifier: LGPL-3.0-only

import "forge-std/Test.sol";
import "../src/SwapApp.sol";

//Version
pragma solidity ^0.8.24;

contract SwapAppTest is Test{

    SwapApp app;
    address uniswapV2SwapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address user = 0xfAf87e196A29969094bE35DfB0Ab9d0b8518dB84; //address with usdt in arbitrum mainnet
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; //USDT address in arbitrum mainnet
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; //DAI address in arbitrum mainnet

    function setUp() public{
        app = new SwapApp(uniswapV2SwapRouterAddress);

    }

    function testHasBeenDeployedCorrectly() public{
        assert(app.V2Router02Address() == uniswapV2SwapRouterAddress);
    }

    function testSwapTokensCorrectly() public{
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6; //5000000
        uint256 amountOutMin = 4 * 1e18;
        uint256 deadline = 1738499328 + 1000000000;
        address[] memory path = new address[](2);
        path[0]= USDT;
        path[1]= DAI;
        IERC20(USDT).approve(address(app), amountIn);


        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);
        app.swapTokens(amountIn, amountOutMin, path, deadline);
        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(user);

        assert(usdtBalanceAfter == usdtBalanceBefore - amountIn);
        assert(daiBalanceAfter > daiBalanceBefore);


        vm.stopPrank();



    }

}