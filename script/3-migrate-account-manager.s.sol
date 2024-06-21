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

        uint256 start = newAccountManager.nextAccountId();
        uint256 end = oldAccountManager.nextAccountId();
        for (uint256 i = start; i < end; ++i) {
            ids.push(i);
            if (ids.length >= 200) {
                break;
            }
        }

        accounts = oldAccountManager.getBatchAccountById(ids);
        names = oldAccountManager.getBatchAccountName(accounts);
        require(ids.length != 0 && ids.length == accounts.length && ids.length == names.length, "Error length");
        for (uint256 i; i < ids.length; ++i) {
            string[] memory socialAccounts;
            newAccountManager.register{value: 0}(accounts[i], names[i], "", "", "", "", "", socialAccounts);
        }

        vm.stopBroadcast();
    }
}
