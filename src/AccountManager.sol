// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@bnb-chain/greenfield-contracts/contracts/interface/ITokenHub.sol";
import "@bnb-chain/greenfield-contracts/contracts/interface/ICrossChain.sol";

import "./interfaces/IAccountManager.sol";

contract AccountManager is IAccountManager,OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint256 public nextAccountId;
    mapping(address => uint256) public accountToId;
    mapping(uint256 => address) public idToAccount;
    mapping(address => string) public accountToName;
    mapping(string => address) public nameToAccount;
    mapping(address => string) public avatars;
    mapping(address => string) public biographies;
    mapping(address => string) public companies;
    mapping(address => string) public locations;
    mapping(address => string) public websites;
    mapping(address => string[]) public socialAccounts;

    // user address => user followings' account ids, ordered by following time.
    mapping(address => EnumerableSetUpgradeable.UintSet) private _followings;
    // user address => user followers' account ids, ordered by followed time.
    mapping(address => EnumerableSetUpgradeable.UintSet) private _followers;

    // ========================== events ===============================
    event Register(address indexed account, uint256 indexed accountId, string name);
    event EditAccount(address indexed account, string oldName, string newName);
    event Follow(address indexed account, address indexed targetAccount);
    event Unfollow(address indexed account, address indexed targetAccount);

    // ==================== initialize functions =======================
    function initialize(address _owner) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
        nextAccountId = 1;
    }

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
    ) external payable returns (bool) {
        require(bytes(_name).length != 0, "Empty name");
        require(accountToId[_account] == 0, "Already registered");
        require(nameToAccount[_name] == address(0), "Duplicated name");

        accountToId[_account] = nextAccountId;
        idToAccount[nextAccountId] = _account;
        ++nextAccountId;

        accountToName[_account] = _name;
        nameToAccount[_name] = _account;
        avatars[_account] = _avatar;
        biographies[_account] = _bio;
        companies[_account] = _company;
        locations[_account] = _location;
        websites[_account] = _website;
        socialAccounts[_account] = _socialAccounts;

        emit Register(_account, accountToId[_account], _name);

        if (msg.value > 0) {
            return transferOut();
        }
        return true;
    }

    function editAccount(
        string calldata _name,
        string calldata _avatar,
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

        avatars[_account] = _avatar;
        biographies[_account] = _bio;
        companies[_account] = _company;
        locations[_account] = _location;
        websites[_account] = _website;
        socialAccounts[_account] = _socialAccounts;

        emit EditAccount(_account, _oldName, _name);
        return true;
    }

    function follow(address _targetAddr) public returns (bool) {
        address _addr = msg.sender;
        uint256 _id = accountToId[_addr];
        uint256 _targetId = accountToId[_targetAddr];
        require(_id > 0 && _targetId > 0, "Not registered");
        require(!_followings[_addr].contains(_targetId), "Already followed");

        _followings[_addr].add(_targetId);
        _followers[_targetAddr].add(_id);

        emit Follow(_addr, _targetAddr);
        return true;
    }

    function unfollow(address _targetAddr) public returns (bool) {
        address _addr = msg.sender;
        uint256 _id = accountToId[_addr];
        uint256 _targetId = accountToId[_targetAddr];
        require(_id > 0 && _targetId > 0, "Not registered");
        require(_followings[_addr].contains(_targetId), "Not following");

        _followings[_addr].remove(_targetId);
        _followers[_targetAddr].remove(_id);

        emit Unfollow(_addr, _targetAddr);
        return true;
    }

    function batchFollow(address[] calldata _targetAddrs) external returns (bool) {
        require(_targetAddrs.length > 0, "Empty addresses");

        for (uint256 i; i < _targetAddrs.length; ++i) {
            follow(_targetAddrs[i]);
        }

        return true;
    }

    function batchUnfollow(address[] calldata _targetAddrs) external returns (bool) {
        require(_targetAddrs.length > 0, "Empty addresses");

        for (uint256 i; i < _targetAddrs.length; ++i) {
            unfollow(_targetAddrs[i]);
        }

        return true;
    }

    // ==================== External view functions =======================
    function getAccountId(address _account) external view returns(uint256) {
        return accountToId[_account];
    }

    function getAccountName(address _account) external view returns(string memory) {
        return accountToName[_account];
    }

    function getBatchAccountById(uint256[] calldata _ids) external view returns(address[] memory _accounts) {
        for (uint256 i; i < _ids.length; ++i) {
            _accounts[i] = idToAccount[_ids[i]];
        }
    }

    function getBatchAccountName(address[] calldata _accounts) external view returns(string[] memory _names) {
        for (uint256 i; i < _accounts.length; ++i) {
            _names[i] = accountToName[_accounts[i]];
        }
    }

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
    ) {
        _id = accountToId[_account];
        _name = accountToName[_account];
        _avatar = avatars[_account];
        _bio = biographies[_account];
        _company = companies[_account];
        _location = locations[_account];
        _website = websites[_account];
        _socialAccounts = socialAccounts[_account];
        _followingNumber = _followings[_account].length();
        _followerNumber = _followers[_account].length();
    }

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
    ) {
        _account = nameToAccount[_name];
        _id = accountToId[_account];
        _avatar = avatars[_account];
        _bio = biographies[_account];
        _company = companies[_account];
        _location = locations[_account];
        _website = websites[_account];
        _socialAccounts = socialAccounts[_account];
        _followingNumber = _followings[_account].length();
        _followerNumber = _followers[_account].length();
    }

    function getFollowing(address _account, uint256 offset, uint256 limit) external view returns(uint256[] memory _ids, uint256 _totalLength) {
        _totalLength = _followings[_account].length();
        if (offset >= _totalLength) {
            return (_ids, _totalLength);
        }

        uint256 count = _totalLength - offset;
        if (count > limit) {
            count = limit;
        }

        _ids = new uint256[](count);
        for (uint256 i; i < count; ++i) {
            _ids[i] = _followings[_account].at(offset+i);
        }
    }

    function getFollower(address _account, uint256 offset, uint256 limit) external view returns(uint256[] memory _ids, uint256 _totalLength) {
        _totalLength = _followers[_account].length();
        if (offset >= _totalLength) {
            return (_ids, _totalLength);
        }

        uint256 count = _totalLength - offset;
        if (count > limit) {
            count = limit;
        }

        _ids = new uint256[](count);
        for (uint256 i; i < count; ++i) {
            _ids[i] = _followers[_account].at(offset+i);
        }
    }

    // ==================== Utils functions =======================
    function isSameString(string calldata str1, string memory str2) public pure returns(bool) {
        return keccak256(bytes(str1)) == keccak256(bytes(str2));
    }

    function transferOut() public payable returns(bool) {
        address tokenHubAddr;
        address crossChainAddr;
        if (block.chainid == 56) {
            tokenHubAddr = 0xeA97dF87E6c7F68C9f95A69dA79E19B834823F25;
            crossChainAddr = 0x77e719b714be09F70D484AB81F70D02B0E182f7d;
        } else if (block.chainid == 97) {
            tokenHubAddr = 0xED8e5C546F84442219A5a987EE1D820698528E04;
            crossChainAddr = 0xa5B2c9194131A4E0BFaCbF9E5D6722c873159cb7;
        } else {
            require(false, "Not support");
        }
        (uint256 relayFee, uint256 minAckRelayFee) = ICrossChain(crossChainAddr).getRelayFees();
        require(msg.value >= 5e15 + relayFee + minAckRelayFee, "Insufficient funds");

        bool transferSuccess = ITokenHub(tokenHubAddr).transferOut{value: msg.value}(msg.sender, 5e15);
        require(transferSuccess, "TransferOut failed");
        return transferSuccess;
    }
}
