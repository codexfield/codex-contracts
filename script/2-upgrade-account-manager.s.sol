// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/interfaces/IAccountManager.sol";
import {AccountManager} from "../src/AccountManager.sol";

contract UpgradeAccountManagerScript is Script {
    address public initOwner;

    address public proxyAdmin;
    address public proxyAccountManager;

    function setUp() public {
        uint256 privateKey = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        initOwner = vm.addr(privateKey);
        console.log("init owner: %s, balance: %s", initOwner, initOwner.balance / 1e18);

        proxyAdmin = vm.envAddress("PROXY_ADMIN");
        console.log("proxyAdmin address: %s", proxyAdmin);

        proxyAccountManager = vm.envAddress("PROXY_ACCOUNT_MANAGER");
        console.log("proxyAccountManager address: %s", proxyAccountManager);
    }

    function run() public {
        vm.startBroadcast(initOwner);
        AccountManager newImpl = new AccountManager();
        require(address(newImpl) != proxyAccountManager, "same impl address");
        console.log("new implMarketPlace address: %s", address(newImpl));

        ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(proxyAccountManager), address(newImpl));
        vm.stopBroadcast();
    }
}
