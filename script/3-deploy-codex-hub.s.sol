// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "../src/Deployer.sol";
import "../src/CodexHub.sol";

contract DeployCodexScript is Script {
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
        CodexHub codexHub = new CodexHub();
        console.log("implCodexHub address: %s", address(codexHub));

        address proxyAdmin = deployer.calcCreateAddress(address(deployer), uint8(1));
        require(proxyAdmin == deployer.proxyAdmin(), "wrong proxyAdmin address");
        console.log("proxyAdmin address: %s", proxyAdmin);
        address proxyCodexHub = deployer.calcCreateAddress(address(deployer), uint8(2));
        require(proxyCodexHub == deployer.proxyContract(), "wrong proxyCodexHub address");
        console.log("proxyCodexHub address: %s", proxyCodexHub);

        deployer.deploy(address(codexHub), initOwner);
        vm.stopBroadcast();
    }
}
