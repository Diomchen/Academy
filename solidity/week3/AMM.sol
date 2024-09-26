// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMMLP is ERC20{
    IERC20 public token_weth;
    IERC20 public token_erc20;

    uint public reserve_weth;
    uint public reserve_erc20;

    uint256 public constant K = 1e18;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
        );

    constructor(address _WETH, address _ERC20) ERC20("Swap", "SS") {
        token_weth = IERC20(_WETH);
        token_erc20 = IERC20(_ERC20);
    }

    function addLP (uint amount0, uint amount1) public {
        token_weth.transferFrom(msg.sender, address(this), amount0);        
        token_erc20.transferFrom(msg.sender, address(this), amount1);

        uint lq = amount0 * amount1;
        
        require(lq > 0, "Insufficient liquidity.");
        reserve_weth = token_weth.balanceOf(address(this));
        reserve_erc20 = token_erc20.balanceOf(address(this));
        
        // update lp
        _mint(msg.sender, lq);

        emit Mint(msg.sender, amount0, amount1);

    } 

    function rmLP(uint liquidity) external  returns (uint amount0, uint amount1){
        uint balance0 = token_weth.balanceOf(address(this));
        uint balance1 = token_erc20.balanceOf(address(this));

        uint _totalSupply = totalSupply();

        amount0 = liquidity*(balance0 / _totalSupply);
        amount1 = liquidity*(balance1 / _totalSupply);

        require(amount0>0 && amount1>0,"Insufficient lq");

        _burn(msg.sender, liquidity);

        token_weth.transfer(msg.sender, amount0);
        token_erc20.transfer(msg.sender, amount1);

        reserve_weth = token_weth.balanceOf(address(this));
        reserve_erc20 = token_erc20.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut){
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns(uint amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == token_erc20 || tokenIn == token_weth, 'INVALID_TOKEN');

        uint balance0 = token_weth.balanceOf(address(this));
        uint balance1 = token_erc20.balanceOf(address(this));

        if (tokenIn == token_weth){
            tokenOut = token_erc20;
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, "Insufficient output");
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }
        else{
            tokenOut = token_weth;
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, "Insufficient output");
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);

        }

        reserve_weth = token_weth.balanceOf(address(this));
        reserve_erc20 = token_erc20.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}