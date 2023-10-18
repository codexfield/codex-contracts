// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/AccountManager.sol";
import "../src/interfaces/IAccountManager.sol";

contract AccountManagerTest is Test {
    address public constant user1 = address(0x0000000000000000000000000000000000000001);
    address public constant user2 = address(0x0000000000000000000000000000000000000002);

    address public owner;
    address public proxyAM;
    AccountManager public accountManager;

    string[] public socialAccounts = ["https://twitter.com/CodexField", "https://t.me/CodexField"];

    function setUp() public {
        uint256 privateKey = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        owner = vm.addr(privateKey);
        console.log("owner: %s", owner);

        accountManager = new AccountManager();
        accountManager.initialize(owner);
        proxyAM = address(accountManager);
    }

    function testInitialize() public {
        assertEq(accountManager.owner(), owner, "wrong owner");
        assertEq(accountManager.nextAccountId(), 1, "nextAccountId expect equal 1");
    }

    function testRegisterInvalidAccount() public {
        vm.prank(user1);
        vm.expectRevert("Not allowed");
        accountManager.register(user2, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
    }

    function testRegisterEmptyName() public {
        vm.prank(user1);
        vm.expectRevert("Empty name");
        accountManager.register(user1, "", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
    }

    function testRegisterAlreadyRegistered() public {
        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
        assertEq(accountManager.socialAccounts(user1, 0), socialAccounts[0], "Expect twitter");
        assertEq(accountManager.socialAccounts(user1, 1), socialAccounts[1], "Expect tg");

        vm.expectRevert("Already registered");
        accountManager.register(user1, "user1", "I am user1", "", "SG", "", socialAccounts);
        vm.stopPrank();
    }

    function testRegisterDuplicatedName() public {
        vm.prank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
        assertEq(accountManager.socialAccounts(user1, 0), socialAccounts[0], "Expect twitter");
        assertEq(accountManager.socialAccounts(user1, 1), socialAccounts[1], "Expect tg");

        vm.prank(user2);
        vm.expectRevert("Duplicated name");
        accountManager.register(user2, "user1", "I am user2", "", "SG", "", socialAccounts);
    }

}
