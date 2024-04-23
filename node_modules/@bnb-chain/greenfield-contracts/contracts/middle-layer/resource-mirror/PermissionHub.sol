// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interface/IPermissionHub.sol";
import "../../interface/ICrossChain.sol";
import "./CmnHub.sol";

contract PermissionHub is PermissionStorage, CmnHub, IPermissionHub {
    constructor() {
        _disableInitializers();
    }

    /*----------------- initializer -----------------*/
    function initialize(address _ERC721_token, address _additional) public initializer {
        __cmn_hub_init_unchained(_ERC721_token, _additional);

        channelId = PERMISSION_CHANNEL_ID;
    }

    function initializeV2() public reinitializer(2) {
        __cmn_hub_init_unchained_v2(INIT_MAX_CALLBACK_DATA_LENGTH);
    }

    /*----------------- middle-layer app function -----------------*/
    /**
     * @dev handle ack cross-chain package from GNFD，it means create/delete operation handled by GNFD successfully.
     *
     * @param sequence The sequence of the ack package
     * @param msgBytes The encoded message bytes sent from GNFD
     * @param callbackGasLimit The gas limit for callback
     */
    function handleAckPackage(
        uint8,
        uint64 sequence,
        bytes calldata msgBytes,
        uint256 callbackGasLimit
    ) external override onlyCrossChain returns (uint256 remainingGas, address refundAddress) {
        uint8 opType = uint8(msgBytes[0]);
        bytes memory pkgBytes = msgBytes[1:];

        if (opType == TYPE_CREATE) {
            (remainingGas, refundAddress) = _handleCreateAckPackage(pkgBytes, sequence, callbackGasLimit);
        } else if (opType == TYPE_DELETE) {
            (remainingGas, refundAddress) = _handleDeleteAckPackage(pkgBytes, sequence, callbackGasLimit);
        } else {
            revert("unexpected operation type");
        }
    }

    /**
     * @dev handle failed ack cross-chain package from GNFD, it means failed to cross-chain syn request to GNFD.
     *
     * @param sequence The sequence of the fail ack package
     * @param msgBytes The encoded message bytes sent from GNFD
     * @param callbackGasLimit The gas limit for callback
     */
    function handleFailAckPackage(
        uint8 channelId,
        uint64 sequence,
        bytes calldata msgBytes,
        uint256 callbackGasLimit
    ) external override onlyCrossChain returns (uint256 remainingGas, address refundAddress) {
        uint8 opType = uint8(msgBytes[0]);
        bytes memory pkgBytes = msgBytes[1:];

        if (opType == TYPE_CREATE) {
            (remainingGas, refundAddress) = _handleCreateFailAckPackage(pkgBytes, sequence, callbackGasLimit);
        } else if (opType == TYPE_DELETE) {
            (remainingGas, refundAddress) = _handleDeleteFailAckPackage(pkgBytes, sequence, callbackGasLimit);
        } else {
            revert("unexpected operation type");
        }

        emit FailAckPkgReceived(channelId, msgBytes);
    }

    /*----------------- external function -----------------*/
    function createPolicy(bytes calldata _data) external payable returns (bool) {
        // check relay fee
        (uint256 relayFee, uint256 minAckRelayFee) = ICrossChain(CROSS_CHAIN).getRelayFees();
        require(msg.value >= relayFee + minAckRelayFee, "not enough fee");
        uint256 _ackRelayFee = msg.value - relayFee;

        createPolicySynPackage memory _pkg = createPolicySynPackage({
            operator: msg.sender,
            data: _data,
            extraData: ""
        });

        ICrossChain(CROSS_CHAIN).sendSynPackage(
            PERMISSION_CHANNEL_ID,
            abi.encodePacked(TYPE_CREATE, abi.encode(_pkg)),
            relayFee,
            _ackRelayFee
        );

        // transfer all the fee to tokenHub
        (bool success, ) = TOKEN_HUB.call{ value: address(this).balance }("");
        require(success, "transfer to tokenHub failed");

        emit CreateSubmitted(msg.sender, msg.sender, string(_data));
        return true;
    }

    function createPolicy(bytes calldata _data, ExtraData memory _extraData) external payable returns (bool) {
        require(_extraData.failureHandleStrategy == FailureHandleStrategy.SkipOnFail, "only SkipOnFail");

        // make sure the extra data is as expected
        require(_extraData.callbackData.length < maxCallbackDataLength, "callback data too long");
        _extraData.appAddress = msg.sender;

        // check relay fee
        (uint256 relayFee, uint256 minAckRelayFee) = ICrossChain(CROSS_CHAIN).getRelayFees();
        require(msg.value >= relayFee + minAckRelayFee, "not enough fee");
        uint256 _ackRelayFee = msg.value - relayFee;

        createPolicySynPackage memory _pkg = createPolicySynPackage({
            operator: msg.sender,
            data: _data,
            extraData: abi.encode(_extraData)
        });

        ICrossChain(CROSS_CHAIN).sendSynPackage(
            PERMISSION_CHANNEL_ID,
            abi.encodePacked(TYPE_CREATE, abi.encode(_pkg)),
            relayFee,
            _ackRelayFee
        );

        // transfer all the fee to tokenHub
        (bool success, ) = TOKEN_HUB.call{ value: address(this).balance }("");
        require(success, "transfer to tokenHub failed");

        emit CreateSubmitted(msg.sender, msg.sender, string(_data));
        return true;
    }

    /**
     * @dev delete a policy and send cross-chain request from BSC to GNFD
     *
     * @param id The policy id
     */
    function deletePolicy(uint256 id) external payable returns (bool) {
        // check relay fee
        (uint256 relayFee, uint256 minAckRelayFee) = ICrossChain(CROSS_CHAIN).getRelayFees();
        require(msg.value >= relayFee + minAckRelayFee, "not enough fee");
        uint256 _ackRelayFee = msg.value - relayFee;

        // check authorization
        address owner = IERC721NonTransferable(ERC721Token).ownerOf(id);
        require(msg.sender == owner, "invalid operator");

        // make sure the extra data is as expected
        CmnDeleteSynPackage memory synPkg = CmnDeleteSynPackage({ operator: owner, id: id, extraData: "" });

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

    function deletePolicy(uint256, ExtraData memory) external payable returns (bool) {
        delegateAdditional();
    }

    /*----------------- internal function -----------------*/
    function _handleCreateFailAckPackage(
        bytes memory pkgBytes,
        uint64,
        uint256 callbackGasLimit
    ) internal returns (uint256 remainingGas, address refundAddress) {
        createPolicySynPackage memory synPkg = abi.decode(pkgBytes, (createPolicySynPackage));

        if (synPkg.extraData.length > 0) {
            ExtraData memory extraData = abi.decode(synPkg.extraData, (ExtraData));
            if (extraData.appAddress != address(0) && callbackGasLimit >= 2300) {
                bytes memory reason;
                bool failed;
                uint256 gasBefore = gasleft();
                try
                    IApplication(extraData.appAddress).greenfieldCall{ gas: callbackGasLimit }(
                        STATUS_UNEXPECTED,
                        channelId,
                        TYPE_CREATE,
                        0,
                        extraData.callbackData
                    )
                {} catch Error(string memory error) {
                    reason = bytes(error);
                    failed = true;
                } catch (bytes memory lowLevelData) {
                    reason = lowLevelData;
                    failed = true;
                }

                uint256 gasUsed = gasBefore - gasleft();
                remainingGas = callbackGasLimit > gasUsed ? callbackGasLimit - gasUsed : 0;
                refundAddress = extraData.refundAddress;
            }
        }
    }

    function versionInfo()
        external
        pure
        override
        returns (uint256 version, string memory name, string memory description)
    {
        return (800_001, "PermissionHub", "init");
    }
}
