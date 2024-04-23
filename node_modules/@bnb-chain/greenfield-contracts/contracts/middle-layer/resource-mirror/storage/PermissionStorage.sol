// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./CmnStorage.sol";

contract PermissionStorage is CmnStorage {
    struct createPolicySynPackage {
        address operator;
        /*
            @dev
            data = rlp data for Object
            {
                "principal": {
                    type: 1, // 1-account, 2-group
                    value: "groupName or address",
                 },
                "resource": "",
                "statements": {
                    "effect": 1,
                    "actions": [1, 2, 3],
                    "resources": ["sub-resource-name"],
                    "expirationTime": 1700808793
                    "limitSize": 5
                },
                "expirationTime": 1700808793
            }
        */
        bytes data;
        bytes extraData; // abi.encode of ExtraData
    }

    // PlaceHolder reserve for future usage
    uint256[50] private __reservedObjectStorageSlots;
}
