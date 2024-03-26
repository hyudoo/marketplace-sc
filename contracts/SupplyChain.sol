//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ISupplyChain {
    function mint(
        address to,
        string memory cid,
        string memory productType
    ) external returns (uint256);
}

contract SupplyChain is
    ERC721Enumerable,
    Ownable,
    AccessControlEnumerable,
    ISupplyChain
{
    // declare variables to store product data and delivery data
    uint private _productIdTracker = 0;
    string private _url;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Mint(address _to, string _productType, uint256 _tokenid);

    struct ProductData {
        string cid;
    }
    // declare mapping to store product data and delivery data
    mapping(uint256 => ProductData) private productData;
    mapping(uint256 => address[]) private transitHistory;

    constructor() ERC721("SupplyChain", "SCN") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(
        address to,
        string memory cid,
        string memory productType
    ) external override returns (uint256) {
        require(
            owner() == _msgSender() || hasRole(MINTER_ROLE, _msgSender()),
            "SupplyChain: must have MINTER_ROLE role to create"
        );
        _productIdTracker += 1;
        uint256 productId = _productIdTracker;
        transitHistory[productId].push(to);
        productData[productId] = ProductData(cid);
        _mint(to, productId);
        emit Mint(to, productType, productId);
        return productId;
    }

    function getCID(uint256 productId) external view returns (string memory) {
        return productData[productId].cid;
    }

    function setCID(uint256 productId, string memory cid) external {
        require(
            ownerOf(productId) == _msgSender() ||
                hasRole(MINTER_ROLE, _msgSender()),
            "SupplyChain: must have MINTER_ROLE role to create"
        );
        productData[productId].cid = cid;
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

    function addMinter(address minter) external onlyOwner {
        grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyOwner {
        revokeRole(MINTER_ROLE, minter);
    }

    function getTransitHistory(
        uint256 productId
    ) external view returns (address[] memory) {
        return transitHistory[productId];
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory _newBaseURI)
    {
        return _url;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _url = _newBaseURI;
    }

    function getProductURI(
        uint256 productId
    ) external view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), productData[productId].cid));
    }

    function customTransferFrom(
        address from,
        address to,
        uint256 productId
    ) public virtual {
        this.safeTransferFrom(from, to, productId);
        transitHistory[productId].push(to);
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
}
