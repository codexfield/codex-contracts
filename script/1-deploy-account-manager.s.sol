// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "../src/Deployer.sol";
import "../src/AccountManager.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployScript is Script {
    address public initOwner;

    function setUp() public {
        uint256 privateKey = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        initOwner = vm.addr(privateKey);
        console.log("init owner: %s, balance: %s", initOwner, initOwner.balance / 1e18);
    }

    function run() public {
        vm.startBroadcast(initOwner);
        AccountManager accountManager = new AccountManager();
        console.log("implAccountManager address: %s", address(accountManager));

        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("proxyAdmin address: %s", address(proxyAdmin));

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(accountManager), address(proxyAdmin), "");
        console.log("proxyAccountManager address: %s", address(proxy));

        accountManager = AccountManager(payable(proxy));
        accountManager.initialize(initOwner);
        vm.stopBroadcast();
    }
}
