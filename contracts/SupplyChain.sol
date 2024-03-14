//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

interface ISupplyChain {
    function mint(address to, uint256 productType) external returns (uint256);
}

contract SupplyChain is
    ERC721Enumerable,
    Ownable,
    AccessControlEnumerable,
    ISupplyChain
{
    uint private _productIdTracker = 0;
    string private _url;
    bytes32 public constant CREATER_ROLE = keccak256("CREATER_ROLE");

    event Mint(address _to, uint256 _productType, uint256 _tokenid);

    constructor() ERC721("SupplyChain", "SCN") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(
        address to,
        uint256 productType
    ) external override returns (uint256) {
        require(
            owner() == _msgSender() || hasRole(CREATER_ROLE, _msgSender()),
            "SupplyChain: must have minter role to mint"
        );
        _productIdTracker += 1;
        uint256 productId = _productIdTracker;
        _mint(to, productId);
        emit Mint(to, productType, productId);
        return productId;
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
