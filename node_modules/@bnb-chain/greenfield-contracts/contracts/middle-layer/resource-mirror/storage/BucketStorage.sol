// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./CmnStorage.sol";

contract BucketStorage is CmnStorage {
    /*----------------- storage -----------------*/

    // BSC to GNFD
    struct CreateBucketSynPackage {
        address creator;
        string name;
        BucketVisibilityType visibility;
        address paymentAddress;
        address primarySpAddress;
        uint64 primarySpApprovalExpiredHeight;
        uint32 globalVirtualGroupFamilyId;
        bytes primarySpSignature;
        uint64 chargedReadQuota;
        bytes extraData; // abi.encode of ExtraData
    }

    enum BucketVisibilityType {
        Unspecified,
        PublicRead,
        Private,
        Inherit // If the bucket Visibility is inherit, it's finally set to private.
    }

    // PlaceHolder reserve for future usage
    uint256[50] private __reservedBucketStorageSlots;
}
