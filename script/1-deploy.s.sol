// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "../src/Deployer.sol";
import "../src/AccountManager.sol";

contract DeployScript is Script {
    address public initOwner;

    function setUp() public {
        uint256 privateKey = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        initOwner = vm.addr(privateKey);
        console.log("init owner: %s, balance: %s", initOwner, initOwner.balance / 1e18);
    }

    function run() public {
        vm.startBroadcast(initOwner);
        Deployer deployer = new Deployer();
        console.log("deployer address: %s", address(deployer));
        AccountManager accountManager = new AccountManager();
        console.log("implAccountManager address: %s", address(accountManager));

        address proxyAdmin = deployer.calcCreateAddress(address(deployer), uint8(1));
        require(proxyAdmin == deployer.proxyAdmin(), "wrong proxyAdmin address");
        console.log("proxyAdmin address: %s", proxyAdmin);
        address proxyAccountManager = deployer.calcCreateAddress(address(deployer), uint8(2));
        require(proxyAccountManager == deployer.proxyAccountManager(), "wrong proxyAccountManager address");
        console.log("proxyAccountManager address: %s", proxyAccountManager);

        deployer.deployAccountManager(address(accountManager), initOwner);
        vm.stopBroadcast();
    }
}
