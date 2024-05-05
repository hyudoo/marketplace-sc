//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Profile {
    struct ProfileInfo {
        string name;
        string bio;
        string avatar;
        bool isPublic;
    }

    mapping(address => ProfileInfo) public profiles;
    address[] private users;

    event ProfileCreated(
        address indexed user,
        string name,
        string bio,
        string avatar
    );

    function createProfile(
        string memory _name,
        string memory _bio,
        string memory _avatar
    ) public {
        profiles[msg.sender] = ProfileInfo(_name, _bio, _avatar, true);
        users.push(msg.sender);

        emit ProfileCreated(msg.sender, _name, _bio, _avatar);
    }

    function getProfileByAddress(
        address _user
    )
        public
        view
        returns (
            string memory name,
            string memory bio,
            string memory avatar,
            bool isPublic
        )
    {
        ProfileInfo memory profile = profiles[_user];
        return (profile.name, profile.bio, profile.avatar, profile.isPublic);
    }

    function updateProfile(
        string memory _name,
        string memory _bio,
        string memory _avatar,
        bool _isPublic
    ) public {
        ProfileInfo storage profile = profiles[msg.sender];
        profile.name = _name;
        profile.bio = _bio;
        profile.avatar = _avatar;
        profile.isPublic = _isPublic;
    }

    function getAllUser() public view returns (address[] memory) {
        return users;
    }
}
