// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./AccountManager.sol";

contract Deployer {
    address public proxyAdmin;
    address public proxyAccountManager;
    address public implAccountManager;

    bool public isAMDeployed;

    constructor() {
        /*
            @dev deploy workflow
            a. Generate contracts addresses in advance first while deploy `Deployer`
            c. Deploy the proxy contracts, checking if they are equal to the generated addresses before
        */
        proxyAdmin = calcCreateAddress(address(this), uint8(1));
        proxyAccountManager = calcCreateAddress(address(this), uint8(2));

        // 1. proxyAdmin
        address deployedProxyAdmin = address(new ProxyAdmin());
        require(deployedProxyAdmin == proxyAdmin, "invalid proxyAdmin address");
    }

    function deployAccountManager(
        address _implAccountManager,
        address _owner
    ) public {
        require(!isAMDeployed, "Already deployed");
        require(_owner != address(0), "invalid owner");

        isAMDeployed = true;
        implAccountManager = _implAccountManager;

        // 1. deploy proxy contract
        address deployedProxyAM = address(new TransparentUpgradeableProxy(implAccountManager, proxyAdmin, ""));
        require(deployedProxyAM == proxyAccountManager, "invalid proxyAccountManager address");

        // 2. transfer admin ownership
        ProxyAdmin(proxyAdmin).transferOwnership(_owner);
        require(ProxyAdmin(proxyAdmin).owner() == _owner, "invalid proxyAdmin owner");

        // 3. init AccountManager
        AccountManager(payable(proxyAccountManager)).initialize(_owner);
    }

    function calcCreateAddress(address _deployer, uint8 _nonce) public pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _deployer, _nonce)))));
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
