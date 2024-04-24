// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@bnb-chain/greenfield-contracts/contracts/middle-layer/TokenHub.sol";
import "@bnb-chain/greenfield-contracts/contracts/middle-layer/resource-mirror/BucketHub.sol";
import "@bnb-chain/greenfield-contracts/contracts/middle-layer/resource-mirror/storage/BucketStorage.sol";
import "@bnb-chain/greenfield-contracts/contracts/CrossChain.sol";

import "./interfaces/ICodexHub.sol";

contract CodexHub is ICodexHub, OwnableUpgradeable {
    uint256 public crossTransferAmount;
    address public bucketHubAddr;
    address public tokenHubAddr;
    address public crossChainAddr;

    function initialize(address _owner) public initializer {
        crossTransferAmount = 2e15;
        __Ownable_init();
        transferOwnership(_owner);
        if (block.chainid == 56) {
            tokenHubAddr = 0xeA97dF87E6c7F68C9f95A69dA79E19B834823F25;
            bucketHubAddr = 0xE909754263572F71bc6aFAc837646A93f5818573;
            crossChainAddr = 0x77e719b714be09F70D484AB81F70D02B0E182f7d;
        } else if (block.chainid == 97) {
            tokenHubAddr = 0xED8e5C546F84442219A5a987EE1D820698528E04;
            bucketHubAddr = 0x5BB17A87D03620b313C39C24029C94cB5714814A;
            crossChainAddr = 0xa5B2c9194131A4E0BFaCbF9E5D6722c873159cb7;
        } else {
            require(false, "Not support");
        }
    }

    function createBucket(bool isPublic, string calldata _name, address _primarySpAddress, uint32 _globalVirtualGroupFamilyId, bytes calldata _extraData) external payable returns (bool) {
        (uint256 relayFee, uint256 minAckRelayFee) = CrossChain(crossChainAddr).getRelayFees();
        uint256 createValue = relayFee + minAckRelayFee;
        uint256 transferValue = relayFee + minAckRelayFee + crossTransferAmount;
        require(msg.value >= createValue + transferValue, "Insufficient funds");

        BucketHub bucketHub = BucketHub(bucketHubAddr);
        BucketStorage.CreateBucketSynPackage memory pkg;
        if (isPublic) {
            pkg.visibility = BucketStorage.BucketVisibilityType.PublicRead;
        } else {
            pkg.visibility = BucketStorage.BucketVisibilityType.Private;
        }
        pkg.creator = msg.sender;
        pkg.name = _name;
        pkg.paymentAddress = msg.sender;
        pkg.primarySpAddress =  _primarySpAddress;
        pkg.primarySpApprovalExpiredHeight = 0;
        pkg.globalVirtualGroupFamilyId = _globalVirtualGroupFamilyId;
        pkg.primarySpSignature = "";
        pkg.chargedReadQuota = 0;
        pkg.extraData = _extraData;

        bool createSuccess = bucketHub.createBucket{value: createValue}(pkg);
        require(createSuccess, "Create bucket failed");

        TokenHub tokenHub = TokenHub(payable(tokenHubAddr));
        bool transferSuccess = tokenHub.transferOut{value: transferValue}(msg.sender, crossTransferAmount);
        require(transferSuccess, "Cross-chain transfer failed");

        return transferSuccess;
    }

    function getCrossTransferAmount() external view returns (uint256) {
        return crossTransferAmount;
    }

    function setCrossTransferAmount(uint256 amount) external onlyOwner {
        crossTransferAmount = amount;
    }
}
