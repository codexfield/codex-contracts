// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IAccountManager {
    // ==================== External functions =======================
    function register(
        address _account,
        string calldata _name,
        string calldata _avatar,
        string calldata _bio,
        string calldata _company,
        string calldata _location,
        string calldata _website,
        string[] calldata _socialAccounts
    ) external returns (bool);

    function editAccount(
        string calldata _name,
        string calldata _avatar,
        string calldata _bio,
        string calldata _company,
        string calldata _location,
        string calldata _website,
        string[] calldata _socialAccounts
    ) external returns (bool);

    function follow(address _targetAddr) external returns (bool);
    function unfollow(address _targetAddr) external returns (bool);
    function batchFollow(address[] calldata _targetAddrs) external returns (bool);
    function batchUnfollow(address[] calldata _targetAddrs) external returns (bool);

    // ==================== View functions ============================
    function getAccountId(address _account) external view returns(uint256);
    function getAccountName(address _account) external view returns(string memory);
    function getBatchAccountById(uint256[] calldata _ids) external view returns(address[] memory _accounts);
    function getBatchAccountName(address[] calldata _accounts) external view returns(string[] memory _names);
    function getFollowing(address _account, uint256 offset, uint256 limit) external view returns(uint256[] memory _ids, uint256 _totalLength);
    function getFollower(address _account, uint256 offset, uint256 limit) external view returns(uint256[] memory _ids, uint256 _totalLength);
    function getAccountDetails(address _account) external view returns(
        uint256 _id,
        string memory _name,
        string memory _avatar,
        string memory _bio,
        string memory _company,
        string memory _location,
        string memory _website,
        string[] memory _socialAccounts,
        uint256 _followingNumber,
        uint256 _followerNumber
    );
    function getAccountDetailsByName(string memory _name) external view returns(
        uint256 _id,
        address _account,
        string memory _avatar,
        string memory _bio,
        string memory _company,
        string memory _location,
        string memory _website,
        string[] memory _socialAccounts,
        uint256 _followingNumber,
        uint256 _followerNumber
    );
}