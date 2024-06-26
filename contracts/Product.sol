//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IProduct {
    function mint(address to, string memory cid) external returns (uint256);
}

contract Product is ERC721Enumerable, AccessControlEnumerable, IProduct {
    uint private _productIdTracker = 0;
    string private _url;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Mint(address _to, uint256 _tokenid);

    mapping(uint256 => string) private cidProduct;
    mapping(uint256 => address[]) private transitHistory;

    constructor() ERC721("Product", "SCN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(
        address to,
        string memory cid
    ) external override returns (uint256) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(MINTER_ROLE, msg.sender),
            "Product: must have MINTER_ROLE role to create"
        );
        _productIdTracker += 1;
        uint256 productId = _productIdTracker;
        transitHistory[productId].push(to);
        cidProduct[productId] = cid;
        _mint(to, productId);
        emit Mint(to, productId);
        return productId;
    }

    function getCID(uint256 productId) external view returns (string memory) {
        return cidProduct[productId];
    }

    function setCID(uint256 productId, string memory _cid) external {
        require(
            ownerOf(productId) == msg.sender ||
                hasRole(MINTER_ROLE, msg.sender),
            "Product: must have MINTER_ROLE role to create"
        );
        cidProduct[productId] = _cid;
    }

    function listProductIds(
        address owner
    ) external view returns (uint256[] memory tokenIds) {
        uint256 balance = balanceOf(owner);
        uint256[] memory ids = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }

        return (ids);
    }

    function getTransitHistory(
        uint256 productId
    ) external view returns (address[] memory) {
        return transitHistory[productId];
    }

    function addTransitHistory(uint256 productId, address to) external {
        require(
            ownerOf(productId) == msg.sender ||
                hasRole(MINTER_ROLE, msg.sender),
            "Product: must have MINTER_ROLE role to create"
        );
        transitHistory[productId].push(to);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory _newBaseURI)
    {
        return _url;
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _url = _newBaseURI;
    }

    function getProductURI(
        uint256 productId
    ) external view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), cidProduct[productId]));
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function hasMinterRole(address _user) public view returns (bool) {
        return hasRole(MINTER_ROLE, _user);
    }

    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(
        address minter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, minter);
    }
}
