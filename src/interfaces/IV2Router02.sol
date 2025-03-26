//SPDX-License-Identifier: LGPL-3.0-only

//Version
pragma solidity ^0.8.24;

interface IV2Router02{


    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}