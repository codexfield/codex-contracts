// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "../src/AccountManager.sol";

contract MigrateAccountManagerScript is Script {
    address public initOwner;
    AccountManager public oldAccountManager;
    AccountManager public newAccountManager;

    uint256[] public ids;
    address[] public accounts;
    string[] public names;

    function setUp() public {
        uint256 privateKey = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        initOwner = vm.addr(privateKey);
        console.log("init owner: %s, balance: %s", initOwner, initOwner.balance / 1e18);

        oldAccountManager = AccountManager(0xbe974b10AF50C5bfD4394C22AdC3d0414cC8Ae32);
        address proxyAccountManager = vm.envAddress("PROXY_ACCOUNT_MANAGER");
        console.log("proxyAccountManager address: %s", proxyAccountManager);
        newAccountManager = AccountManager(proxyAccountManager);
    }

    function run() public {
        vm.startBroadcast(initOwner);
        string[] memory socialAccounts;
        for (uint256 i = newAccountManager.nextAccountId(); i < oldAccountManager.nextAccountId(); ++i) {
            ids.push(i);
            if (ids.length >= 100) {
                break;
            }
        }

        require(ids.length != 0 && ids.length == accounts.length && ids.length == names.length, "Error length");
        accounts = oldAccountManager.getBatchAccountById(ids);
        names = oldAccountManager.getBatchAccountName(accounts);

        for (uint256 i; i < ids.length; ++i) {
            newAccountManager.register{value: 0}(accounts[i], names[i], "", "", "", "", "", socialAccounts);
        }

        vm.stopBroadcast();
    }
}
