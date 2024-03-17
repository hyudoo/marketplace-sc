//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Delivery.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

interface ISupplyChain {
    function mint(
        address to,
        string memory cid,
        uint256 productType
    ) external returns (uint256);
}

contract SupplyChain is
    ERC721Enumerable,
    Ownable,
    AccessControlEnumerable,
    ISupplyChain
{
    uint private _productIdTracker = 0;
    string private _url;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Mint(address _to, uint256 _productType, uint256 _tokenid);

    struct ProductData {
        string cid;
    }

    mapping(uint256 => ProductData) private productData;
    mapping(string => address[]) private transitHistory;

    constructor() ERC721("SupplyChain", "SCN") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(
        address to,
        string memory cid,
        uint256 productType
    ) external override returns (uint256) {
        require(
            owner() == _msgSender() || hasRole(MINTER_ROLE, _msgSender()),
            "SupplyChain: must have MINTER_ROLE role to create"
        );
        _productIdTracker += 1;
        uint256 productId = _productIdTracker;
        transitHistory[cid].push(to);
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
