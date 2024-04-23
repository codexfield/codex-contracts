// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./Deployer.sol";
import "./GnfdProxy.sol";
import "./GnfdProxyAdmin.sol";
import "./GnfdLightClient.sol";
import "./CrossChain.sol";
import "./RelayerHub.sol";
import "./middle-layer/GovHub.sol";
import "./middle-layer/TokenHub.sol";
import "./middle-layer/resource-mirror/BucketHub.sol";
import "./middle-layer/resource-mirror/ObjectHub.sol";
import "./middle-layer/resource-mirror/GroupHub.sol";
import "./middle-layer/resource-mirror/PermissionHub.sol";

contract PermissionDeployer {
    address public immutable proxyPermissionHub;
    Deployer public immutable oldDeployer;

    address public implPermissionHub;
    address public permissionToken;
    address public addPermissionHub;
    bytes20 public deployRepoCommitId;

    bool public deployed;
    address public operator;

    modifier onlyOperator() {
        require(msg.sender == operator, "only operator");
        _;
    }

    constructor(address _oldDeployer, bytes20 _deployRepoCommitId) {
        operator = msg.sender;
        oldDeployer = Deployer(_oldDeployer);
        deployRepoCommitId = _deployRepoCommitId;

        proxyPermissionHub = calcCreateAddress(address(this), uint8(1));
    }

    function deploy(
        address _implPermissionHub,
        address _addPermissionHub,
        address _permissionToken
    ) external onlyOperator {
        require(!deployed, "only not deployed");
        deployed = true;
        implPermissionHub = _implPermissionHub;
        permissionToken = _permissionToken;
        addPermissionHub = _addPermissionHub;

        address deployedProxyPermissionHub = address(new GnfdProxy(_implPermissionHub, oldDeployer.proxyAdmin(), ""));
        require(deployedProxyPermissionHub == proxyPermissionHub, "invalid proxyPermissionHub address");
        PermissionHub(payable(proxyPermissionHub)).initialize(_permissionToken, _addPermissionHub);
        PermissionHub(payable(proxyPermissionHub)).initializeV2();

        require(
            PermissionHub(payable(proxyPermissionHub)).additional() == _addPermissionHub,
            "invalid _addPermissionHub address on proxyPermissionHub"
        );
        require(
            Config(deployedProxyPermissionHub).PROXY_ADMIN() == oldDeployer.proxyAdmin(),
            "invalid proxyAdmin address on Config"
        );
        require(
            Config(deployedProxyPermissionHub).GOV_HUB() == oldDeployer.proxyGovHub(),
            "invalid proxyGovHub address on Config"
        );
        require(
            Config(deployedProxyPermissionHub).CROSS_CHAIN() == oldDeployer.proxyCrossChain(),
            "invalid proxyCrossChain address on Config"
        );
        require(
            Config(deployedProxyPermissionHub).TOKEN_HUB() == oldDeployer.proxyTokenHub(),
            "invalid proxyTokenHub address on Config"
        );
        require(
            Config(deployedProxyPermissionHub).GOV_HUB() == oldDeployer.proxyGovHub(),
            "invalid proxyGovHub address on Config"
        );
        require(
            Config(deployedProxyPermissionHub).RELAYER_HUB() == oldDeployer.proxyRelayerHub(),
            "invalid proxyRelayerHub address on Config"
        );
        require(
            Config(deployedProxyPermissionHub).PERMISSION_HUB() == deployedProxyPermissionHub,
            "invalid proxyPermissionHub address on Config"
        );
        require(
            Config(_addPermissionHub).PERMISSION_HUB() == deployedProxyPermissionHub,
            "invalid proxyPermissionHub address on Config"
        );
        require(
            Config(_addPermissionHub).CROSS_CHAIN() == oldDeployer.proxyCrossChain(),
            "invalid proxyPermissionHub address on Config"
        );
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function calcCreateAddress(address _deployer, uint8 _nonce) public pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _deployer, _nonce)))));
    }
}
