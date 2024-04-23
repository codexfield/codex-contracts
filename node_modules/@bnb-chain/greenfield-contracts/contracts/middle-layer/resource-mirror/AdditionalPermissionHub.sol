// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/DoubleEndedQueueUpgradeable.sol";

import "./storage/PermissionStorage.sol";
import "../../interface/IApplication.sol";
import "../../interface/ICrossChain.sol";
import "../../interface/IERC721NonTransferable.sol";

// Highlight: This contract must have the same storage layout as PermissionHub
// which means same state variables and same order of state variables.
// Because it will be used as a delegate call target.
// NOTE: The inherited contracts order must be the same as PermissionHub.
contract AdditionalPermissionHub is PermissionStorage {
    // PlaceHolder corresponding to `Initializable` contract
    uint8 private _initialized;
    bool private _initializing;

    /**
     * @dev delete a policy and send cross-chain request from BSC to GNFD
     *
     * @param id The policy id
     * @param _extraData The extra data for crosschain callback
     */
    function deletePolicy(uint256 id, ExtraData memory _extraData) external payable returns (bool) {
        require(_extraData.failureHandleStrategy == FailureHandleStrategy.SkipOnFail, "only SkipOnFail");

        // make sure the extra data is as expected
        require(_extraData.callbackData.length < maxCallbackDataLength, "callback data too long");
        _extraData.appAddress = msg.sender;

        // check relay fee
        (uint256 relayFee, uint256 minAckRelayFee) = ICrossChain(CROSS_CHAIN).getRelayFees();
        require(msg.value >= relayFee + minAckRelayFee, "not enough fee");
        uint256 _ackRelayFee = msg.value - relayFee;

        // check authorization
        address owner = IERC721NonTransferable(ERC721Token).ownerOf(id);
        require(msg.sender == owner, "invalid operator");

        // make sure the extra data is as expected
        CmnDeleteSynPackage memory synPkg = CmnDeleteSynPackage({
            operator: owner,
            id: id,
            extraData: abi.encode(_extraData)
        });

        ICrossChain(CROSS_CHAIN).sendSynPackage(
            PERMISSION_CHANNEL_ID,
            abi.encodePacked(TYPE_DELETE, abi.encode(synPkg)),
            relayFee,
            _ackRelayFee
        );

        // transfer all the fee to tokenHub
        (bool success, ) = TOKEN_HUB.call{ value: address(this).balance }("");
        require(success, "transfer to tokenHub failed");

        emit DeleteSubmitted(owner, msg.sender, id);
        return true;
    }
}
