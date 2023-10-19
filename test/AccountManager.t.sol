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

        accountManager.register(address(this), "test", "I am test", "", "", "", socialAccounts);
    }

    function testInitialize() public {
        assertEq(accountManager.owner(), owner, "wrong owner");
        assertEq(accountManager.nextAccountId(), 2, "nextAccountId expect equal 1");
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

    function testRegister(
        string calldata _name,
        string calldata _bio,
        string calldata _company,
        string calldata _location,
        string calldata _website,
        string[] calldata _socialAccounts
    ) public {
        vm.assume(bytes(_name).length != 0);

        vm.prank(user1);
        accountManager.register(user1, _name, _bio, _company, _location, _website, _socialAccounts);
        assertEq(accountManager.nextAccountId(), 3, "nextAccountId expect 3");
    }

    function testEditAccountEmptyName() public {
        vm.prank(address(this));
        vm.expectRevert("Empty name");
        accountManager.editAccount("", "I am test", "codexfield", "SG", "www.codexfield.com", socialAccounts);
    }

    function testEditAccountDuplicatedName() public {
        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);

        vm.expectRevert("Duplicated name");
        accountManager.editAccount("test", "I am user1", "", "SG", "", socialAccounts);
        vm.stopPrank();
    }

    function testEditAccountSameName() public {
        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
        accountManager.editAccount("user1", "I am user1", "", "SG", "", socialAccounts);
        assertEq(accountManager.companies(user1), "", "user1's company expect empty");
        vm.stopPrank();
    }

    function testEditAccountNewName() public {
        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
        accountManager.editAccount("new_user1", "I am new user1", "", "SG", "", socialAccounts);
        assertEq(accountManager.nameToAccount("user1"), address(0), "old name expect deleted");
        vm.stopPrank();
    }

    function testEditAccount(
        string calldata _name,
        string calldata _bio,
        string calldata _company,
        string calldata _location,
        string calldata _website,
        string[] calldata _socialAccounts
    ) public {
        vm.assume(bytes(_name).length != 0);
        vm.assume(!accountManager.isSameString(_name, "test"));

        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
        bool ret = accountManager.editAccount(_name, _bio, _company, _location, _website, _socialAccounts);
        assertTrue(ret, "expect success");
        vm.stopPrank();
    }

    function testFollowUnregistered() public {
        vm.prank(user1);
        vm.expectRevert("Not registered");
        accountManager.follow(address(this));

        vm.prank(address(this));
        vm.expectRevert("Not registered");
        accountManager.follow(user1);
    }

    function testFollowAlreadyFollowed() public {
        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
        bool ret = accountManager.follow(address(this));
        assertTrue(ret, "expect follow success");

        vm.expectRevert("Already followed");
        accountManager.follow(address(this));
        vm.stopPrank();
    }

    function testUnfollowUnregistered() public {
        vm.prank(user1);
        vm.expectRevert("Not registered");
        accountManager.unfollow(address(this));

        vm.prank(address(this));
        vm.expectRevert("Not registered");
        accountManager.unfollow(user1);
    }

    function testUnfollowNotFollowed() public {
        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);

        vm.expectRevert("Not following");
        accountManager.unfollow(address(this));
        vm.stopPrank();
    }

    function testUnfollowSuccess() public {
        vm.startPrank(user1);
        accountManager.register(user1, "user1", "I am user1", "codexfield", "SG", "www.codexfield.com", socialAccounts);
        bool ret = accountManager.follow(address(this));
        assertTrue(ret, "expect follow success");

        ret = accountManager.unfollow(address(this));
        assertTrue(ret, "expect unfollow success");
        vm.stopPrank();
    }
}
