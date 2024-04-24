// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICodexHub {
    function createBucket(
        bool isPublic,
        string calldata _name,
        address _primarySpAddress,
        uint32 _globalVirtualGroupFamilyId,
        bytes calldata _extraData
    ) external payable returns (bool);
    function getCrossTransferAmount() external view returns (uint256);
}