// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/structs/EnumerableMapUpgradeable.sol";

import "./interfaces/IAccountManager.sol";

contract AccountManager is IAccountManager,OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint256 public nextAccountId;
    mapping(address => uint256) public accountToId;
    mapping(uint256 => address) public idToAccount;
    mapping(address => string) public accountToName;
    mapping(string => address) public nameToAccount;
    mapping(address => string) public biographies;
    mapping(address => string) public companies;
    mapping(address => string) public locations;
    mapping(address => string) public websites;
    mapping(address => string[]) public socialAccounts;

    // user address => user followings' account ids, ordered by following time.
    mapping(address => EnumerableSetUpgradeable.UintSet) private _followings;
    // user address => user followers' account ids, ordered by followed time.
    mapping(address => EnumerableSetUpgradeable.UintSet) private _followers;

    // ==================== initialize functions =======================
    function initialize(address _owner) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
        nextAccountId = 1;
    }

    function register(
        address _account,
        string calldata _name,
        string calldata _bio,
        string calldata _company,
        string calldata _location,
        string calldata _website,
        string[] calldata _socialAccounts
    ) external returns (bool) {
        require(_account == msg.sender, "Not allowed");
        require(bytes(_name).length != 0, "Empty name");
        require(accountToId[_account] == 0, "Already registered");
        require(nameToAccount[_name] == address(0), "Duplicated name");

        accountToId[_account] = nextAccountId;
        idToAccount[nextAccountId] = _account;
        ++nextAccountId;

        accountToName[_account] = _name;
        nameToAccount[_name] = _account;
        biographies[_account] = _bio;
        companies[_account] = _company;
        locations[_account] = _location;
        websites[_account] = _website;
        socialAccounts[_account] = _socialAccounts;
        return true;
    }

    function editAccount(
        string calldata _name,
        string calldata _bio,
        string calldata _company,
        string calldata _location,
        string calldata _website,
        string[] calldata _socialAccounts
    ) external returns (bool) {
        address _account = msg.sender;
        string memory _oldName = accountToName[_account];
        require(bytes(_name).length != 0, "Empty name");
        require(isSameString(_name, _oldName) || nameToAccount[_name] == address(0), "Duplicated name");

        if (!isSameString(_name, _oldName)) {
            delete nameToAccount[_oldName];
            accountToName[_account] = _name;
            nameToAccount[_name] = _account;
        }

        biographies[_account] = _bio;
        companies[_account] = _company;
        locations[_account] = _location;
        websites[_account] = _website;
        socialAccounts[_account] = _socialAccounts;
        return true;
    }

    function follow(address _targetAddr) external returns (bool) {
        address _addr = msg.sender;
        uint256 _id = accountToId[_addr];
        uint256 _targetId = accountToId[_targetAddr];
        require(_id > 0 && _targetId > 0, "Not registered");
        require(!_followings[_addr].contains(_targetId), "Already followed");

        _followings[_addr].add(_targetId);
        _followers[_targetAddr].add(_id);
        return true;
    }

    function unfollow(address _targetAddr) external returns (bool) {
        address _addr = msg.sender;
        uint256 _id = accountToId[_addr];
        uint256 _targetId = accountToId[_targetAddr];
        require(_id > 0 && _targetId > 0, "Not registered");
        require(_followings[_addr].contains(_targetId), "Not following");

        _followings[_addr].remove(_targetId);
        _followers[_targetAddr].remove(_id);
        return true;
    }

    function isSameString(string calldata str1, string memory str2) public pure returns(bool) {
        return keccak256(bytes(str1)) == keccak256(bytes(str2));
    }
}
