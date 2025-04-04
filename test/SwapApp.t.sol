//SPDX-License-Identifier: LGPL-3.0-only

import "forge-std/Test.sol";
import "../src/SwapApp.sol";

//Version
pragma solidity ^0.8.24;

contract SwapAppTest is Test {
    SwapApp app;
    address uniswapV2SwapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address user = 0xfAf87e196A29969094bE35DfB0Ab9d0b8518dB84; //address with usdt in arbitrum mainnet
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; //USDT address in arbitrum mainnet
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; //DAI address in arbitrum mainnet
    address feeReceiver = vm.addr(3);

    function setUp() public {
        app = new SwapApp(uniswapV2SwapRouterAddress, feeReceiver);
    }

    function testHasBeenDeployedCorrectly() public {
        assert(app.V2Router02Address() == uniswapV2SwapRouterAddress);
    }

    //Swap Tokens (without fee)
    function testShouldRevertIfPathLengthInsuficient() public {
        //Set parameters
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6; //5000000
        uint256 amountOutMin = 4 * 1e18;
        uint256 deadline = 1738499328 + 1000000000;
        address[] memory path = new address[](1);
        path[0] = USDT;

        //Approve the contract to spend usdt
        IERC20(USDT).approve(address(app), amountIn);

        //Save initial balance
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);

        //Expect Revert
        vm.expectRevert("Invalid path length");
        app.swapTokens(amountIn, amountOutMin, path, deadline);

        vm.stopPrank();
    }

    function testShouldRevertIfNotEnoughTokensApproved() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6; //5000000
        uint256 amountOutMin = 4 * 1e18;
        uint256 deadline = 1738499328 + 1000000000;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;
        IERC20(USDT).approve(address(app), amountIn - 1);

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);

        vm.expectRevert("ERC20: transfer amount exceeds allowance");

        app.swapTokens(amountIn, amountOutMin, path, deadline);
        vm.stopPrank();
    }

    function testSwapTokensCorrectly() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6; //5000000
        uint256 amountOutMin = 4 * 1e18;
        uint256 deadline = 1738499328 + 1000000000;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;
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

    //Add Liquidity
    function testLiquidityShouldRevertIfTokensAreTheSame() public {
        vm.startPrank(user);
        address tokenA = USDT;
        address tokenB = USDT;
        uint256 amountADesired = 5 * 1e6;
        uint256 amountBDesired = 5 * 1e6;
        uint256 amountAMin = 4 * 1e6;
        uint256 amountBMin = 4 * 1e6;
        uint256 deadline = 1738499328 + 1000000000;

        IERC20(USDT).approve(address(app), amountADesired);

        // Save initial balances (optional, to verify they don't change)
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);

        // Expect it to revert because the tokens are the same
        vm.expectRevert("Tokens must be different");
        app.addLiquidityToPool(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, deadline);

        vm.stopPrank();
    }

    function testShouldRevertIfDeadlineAlreadyExpired() public {
        vm.startPrank(user);
        address tokenA = USDT;
        address tokenB = DAI;
        uint256 amountADesired = 5 * 1e6;
        uint256 amountBDesired = 5 * 1e18;
        uint256 amountAMin = 4 * 1e6;
        uint256 amountBMin = 4 * 1e18;
        uint256 deadline = block.timestamp - 24 hours; // Deadline in the past

        IERC20(USDT).approve(address(app), amountADesired);
        IERC20(DAI).approve(address(app), amountBDesired);

        // Save initial balances (optional, to verify they don't change)
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);

        vm.expectRevert("Deadline has expired");
        app.addLiquidityToPool(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, deadline);

        vm.stopPrank();
    }

    function testShouldRevertIfAmountDesiredIsZero() public {
        vm.startPrank(user);
        address tokenA = USDT;
        address tokenB = DAI;
        uint256 amountADesired = 5 * 1e6;
        uint256 amountBDesired = 0;
        uint256 amountAMin = 4 * 1e6;
        uint256 amountBMin = 4 * 1e18;
        uint256 deadline = block.timestamp + 24 hours; // Deadline in the future

        IERC20(USDT).approve(address(app), amountADesired);
        IERC20(DAI).approve(address(app), amountBDesired);

        // Save initial balances (optional, to verify they don't change)
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);

        vm.expectRevert("Amounts must be greater than zero");
        app.addLiquidityToPool(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, deadline);

        vm.stopPrank();
    }

    function testShouldRevertIfAmountMinsExceedDesired() public {
        vm.startPrank(user);
        address tokenA = USDT;
        address tokenB = DAI;
        uint256 amountADesired = 5 * 1e6;
        uint256 amountBDesired = 5 * 1e18;
        uint256 amountAMin = 6 * 1e6;
        uint256 amountBMin = 6 * 1e18;
        uint256 deadline = block.timestamp + 24 hours; // Deadline in the future

        IERC20(USDT).approve(address(app), amountADesired);
        IERC20(DAI).approve(address(app), amountBDesired);

        // Save initial balances (optional, to verify they don't change)
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);

        vm.expectRevert("Minimum amounts exceed desired amounts");
        app.addLiquidityToPool(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, deadline);

        vm.stopPrank();
    }

    function testAddLiquidityCorrectly() public {
        vm.startPrank(user); // Simulates the user executing the transaction

        // Set parameters
        address tokenA = USDT; // USDT (6 decimals)
        address tokenB = DAI; // DAI (18 decimals)
        uint256 amountADesired = 5 * 1e6; // 5 USDT
        uint256 amountBDesired = 5 * 1e18; // 5 DAI
        uint256 amountAMin = 4 * 1e6; // 4 USDT (less than or equal to amountADesired)
        uint256 amountBMin = 4 * 1e18; // 4 DAI (less than or equal to amountBDesired)
        uint256 deadline = block.timestamp + 24 hours; // Deadline in the future

        // Approve the contract to spend both tokens
        IERC20(tokenA).approve(address(app), amountADesired);
        IERC20(tokenB).approve(address(app), amountBDesired);

        // Save initial balances
        uint256 usdtBalanceBefore = IERC20(tokenA).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(tokenB).balanceOf(user);

        // Execute the function and expect the event
        vm.expectEmit(true, true, false, false);
        (uint256 amountA, uint256 amountB, uint256 liquidity) =
            app.addLiquidityToPool(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, deadline);

        // Verify balances afterward
        uint256 usdtBalanceAfter = IERC20(tokenA).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(tokenB).balanceOf(user);

        // Verify that tokens were used and excess was returned (if applicable)
        assert(
            usdtBalanceBefore - usdtBalanceAfter
                == amountADesired - (amountADesired > amountA ? amountADesired - amountA : 0)
        );
        assert(
            daiBalanceBefore - daiBalanceAfter
                == amountBDesired - (amountBDesired > amountB ? amountBDesired - amountB : 0)
        );

        // Verify that liquidity was received
        assertGt(liquidity, 0, "No liquidity tokens received");

        vm.stopPrank();
    }

    //Remove Liquidity

    function testShouldRevertIfAddressZero() public {
        vm.startPrank(user);
        address tokenA = address(0);
        address tokenB = DAI; //Set tokenB to address(0) to try the other option for this test
        uint256 liquidity = 10;
        uint256 amountAMin = 5 * 1e6;
        uint256 amountBMin = 5 * 1e18;
        uint256 deadline = block.timestamp + 48 hours;

        vm.expectRevert("Invalid token addresses");
        app.removeLiquidityFromPool(tokenA, tokenB, liquidity, amountAMin, amountBMin, deadline);

        vm.stopPrank();
    }

    function testShouldRevertIfLiquidityIsZero() public {
        vm.startPrank(user);
        address tokenA = USDT;
        address tokenB = DAI;
        uint256 liquidity = 0;
        uint256 amountAMin = 5 * 1e6;
        uint256 amountBMin = 5 * 1e18;
        uint256 deadline = block.timestamp + 48 hours;

        vm.expectRevert("Liquidity must be greater than zero");
        app.removeLiquidityFromPool(tokenA, tokenB, liquidity, amountAMin, amountBMin, deadline);

        vm.stopPrank();
    }

    function testRemoveLiquidityCorrectly() public {
        vm.startPrank(user);
        address tokenA = USDT;
        address tokenB = DAI;
        uint256 liquidity = 10;
        uint256 amountAMin = 5 * 1e6;
        uint256 amountBMin = 5 * 1e18;
        uint256 deadline = block.timestamp + 48 hours;

        address pair = app.getPair(tokenA, tokenB);

        deal(pair, user, liquidity);
        vm.prank(user);
        IERC20(pair).approve(address(app), liquidity);

        uint256 usdtBalanceBefore = IERC20(tokenA).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(tokenB).balanceOf(user);
        uint256 liquidityBalanceBefore = IERC20(pair).balanceOf(user);

        app.removeLiquidityFromPool(tokenA, tokenB, liquidity, amountAMin, amountBMin, deadline);

        uint256 usdtBalanceAfter = IERC20(tokenA).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(tokenB).balanceOf(user);
        uint256 liquidityBalanceAfter = IERC20(pair).balanceOf(user);

        assert(usdtBalanceAfter > usdtBalanceBefore); // Received USDT
        assert(daiBalanceAfter > daiBalanceBefore); // Received DAI
        assert(liquidityBalanceBefore - liquidityBalanceAfter == liquidity); // Lost liquidity

        // Verify that minimums were respected
        assert(usdtBalanceAfter - usdtBalanceBefore >= amountAMin); // USDT minimum respected
        assert(daiBalanceAfter - daiBalanceBefore >= amountBMin); // DAI minimum respected

        vm.stopPrank();
    }

    //Swapp Tokens with Fee

    function testShouldRevertWithInsuficientPathFee() public {
        //Set parameters
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6; //5000000
        uint256 amountOutMin = 4 * 1e18;
        uint256 deadline = 1738499328 + 1000000000;
        address[] memory path = new address[](1);
        path[0] = USDT;
        uint256 feePercent = 200;

        //Approve the contract to spend usdt
        IERC20(USDT).approve(address(app), amountIn);

        //Save initial balance
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);

        //Expect Revert
        vm.expectRevert("Invalid path length");
        app.swapTokensWithFee(amountIn, amountOutMin, path, deadline, feePercent);

        vm.stopPrank();
    }

    function testSwapTokensWithFeeCorrectly() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6; //5000000
        uint256 amountOutMin = 4 * 1e18;
        uint256 deadline = 1738499328 + 1000000000;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;
        uint256 feePercent = 200;

        deal(USDT, user, amountIn);

        IERC20(USDT).approve(address(app), amountIn);

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);
        uint256 feeReceiverBalanceBefore = IERC20(USDT).balanceOf(feeReceiver);

        app.swapTokensWithFee(amountIn, amountOutMin, path, deadline, feePercent);

        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(user);
        uint256 feeReceiverBalanceAfter = IERC20(USDT).balanceOf(feeReceiver);

        assert(usdtBalanceAfter == usdtBalanceBefore - amountIn);
        assert(daiBalanceAfter > daiBalanceBefore);
        assert(daiBalanceAfter - daiBalanceBefore >= amountOutMin); // Respects the minimum
        assert(feeReceiverBalanceAfter - feeReceiverBalanceBefore == (feePercent * amountIn / 10000)); // Fee transferred

        vm.stopPrank();
    }
}
