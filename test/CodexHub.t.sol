// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/CodexHub.sol";
import "@bnb-chain/greenfield-contracts/contracts/middle-layer/resource-mirror/BucketHub.sol";

contract CodexHubTest is Test {
    address public constant owner = address(0x0000000000000000000000000000000000000001);
    address public constant user1 = address(0x0000000000000000000000000000000000000002);
    address public constant user2 = address(0x0000000000000000000000000000000000000003);

    CodexHub public codexHub;
    address public bucketHubAddr;
    address public primarySp1;

    function setUp() public {
        codexHub = new CodexHub();
        codexHub.initialize(owner);

        if (block.chainid == 56) {
            bucketHubAddr = 0xE909754263572F71bc6aFAc837646A93f5818573;
            primarySp1 = address(0);
        } else if (block.chainid == 97) {
            bucketHubAddr = 0x5BB17A87D03620b313C39C24029C94cB5714814A;
            primarySp1 = 0x89A1CC91B642DECbC4789474694C606E0E0c420b;
        }

        vm.deal(user1, 100e18);
    }

    function testInitialize() public {
        assertEq(codexHub.owner(), owner, "wrong owner");
        assertEq(codexHub.crossTransferAmount(), 2e15, "wrong crossAmount");
    }

    function testGrantWithWrongCode() public {
        vm.startPrank(user1);
        vm.expectRevert(bytes("invalid authorization code"));
        BucketHub bucketHub = BucketHub(bucketHubAddr);
        bucketHub.grant(address(codexHub), 7, block.timestamp + 100 days);
        vm.stopPrank();
    }

    function testCreateBucket() public {
        vm.startPrank(user2);
        BucketHub bucketHub = BucketHub(bucketHubAddr);
        bucketHub.grant(address(codexHub), 3, ~uint256(0));

        uint256 val = 2 * (25e13 + 130e13) + codexHub.crossTransferAmount();
        bool isSuccess = codexHub.createBucket{value: val}(false, "my-repo", primarySp1, 40, "");
        assertEq(isSuccess, true, "create bucket failed");
        console.log("bal: ", user2.balance);
        vm.stopPrank();
    }

    function testSetCrossTransferAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        codexHub.setCrossTransferAmount(3e15);

        vm.startPrank(owner);
        codexHub.setCrossTransferAmount(3e15);
        assertEq(codexHub.crossTransferAmount(), 3e15, "wrong crossAmount");
    }
}
