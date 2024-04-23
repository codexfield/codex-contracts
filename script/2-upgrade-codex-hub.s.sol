// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {CodexHub} from "../src/CodexHub.sol";

contract UpgradeCodexHubScript is Script {
    address public initOwner;

    address public proxyAdmin;
    address public proxyCodexHub;

    function setUp() public {
        uint256 privateKey = uint256(vm.envBytes32("OWNER_PRIVATE_KEY"));
        initOwner = vm.addr(privateKey);
        console.log("init owner: %s, balance: %s", initOwner, initOwner.balance / 1e18);

        proxyAdmin = vm.envAddress("PROXY_ADMIN_CODEX_HUB");
        console.log("proxyAdmin address: %s", proxyAdmin);

        proxyCodexHub = vm.envAddress("PROXY_CODEX_HUB");
        console.log("proxyCodexHub address: %s", proxyCodexHub);
    }

    function run() public {
        vm.startBroadcast(initOwner);
        CodexHub newImpl = new CodexHub();
        require(address(newImpl) != proxyCodexHub, "same impl address");
        console.log("new implCodexHub address: %s", address(newImpl));

        ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(proxyCodexHub), address(newImpl));
        vm.stopBroadcast();
    }
}
