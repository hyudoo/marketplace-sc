//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Product.sol";

contract MarketPlace is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    Product private product;
    IERC20 private token;

    struct ProductDetail {
        address payable author;
        uint256 productId;
        uint256 price;
    }

    event ListProduct(
        address indexed _author,
        uint256 _productId,
        uint256 _price
    );

    event UnlistProduct(address indexed _author, uint256 _productId);
    event BuyProduct(
        address indexed _author,
        uint256 _productId,
        uint256 _price
    );
    event UpdatePrice(uint256 _productId, uint256 _price);
    event SetToken(IERC20 _token);
    event SetFeeRate(uint256 _feeRate);
    event SetProduct(Product _product);

    uint256 private feeRate = 5; // percentage
    mapping(uint256 => ProductDetail) listProductDetail;

    constructor(IERC20 _token, Product _product) Ownable(msg.sender) {
        product = _product;
        token = _token;
    }

    function getListedProducts() public view returns (ProductDetail[] memory) {
        uint balance = product.balanceOf(address(this));
        ProductDetail[] memory myProduct = new ProductDetail[](balance);

        for (uint i = 0; i < balance; i++) {
            myProduct[i] = listProductDetail[
                product.tokenOfOwnerByIndex(address(this), i)
            ];
        }
        return myProduct;
    }

    function getListedProductByID(
        uint256 _productId
    ) public view returns (ProductDetail memory) {
        return listProductDetail[_productId];
    }

    function listProduct(uint256 _productId, uint256 _price) public {
        require(
            product.ownerOf(_productId) == msg.sender,
            "You are not the owner of this Product"
        );
        require(
            product.getApproved(_productId) == address(this),
            "Marketplace is not approved to transfer this Product"
        );

        listProductDetail[_productId] = ProductDetail(
            payable(msg.sender),
            _productId,
            _price
        );

        product.safeTransferFrom(msg.sender, address(this), _productId);
        emit ListProduct(msg.sender, _productId, _price);
    }

    function updatePriceProduct(uint256 _productId, uint256 _price) public {
        require(
            product.ownerOf(_productId) == address(this),
            "This Product doesn't exist on marketplace"
        );
        require(
            listProductDetail[_productId].author == msg.sender,
            "Only owner can update price of this Product"
        );

        listProductDetail[_productId].price = _price;
        emit UpdatePrice(_productId, _price);
    }

    function unlistProduct(uint256 _productId) public {
        require(
            product.ownerOf(_productId) == address(this),
            "This Product doesn't exist on marketplace"
        );
        require(
            listProductDetail[_productId].author == msg.sender,
            "Only owner can unlist this Product"
        );

        product.safeTransferFrom(address(this), msg.sender, _productId);
        emit UnlistProduct(msg.sender, _productId);
    }

    function buyProduct(uint256 _productId) public {
        require(
            token.balanceOf(msg.sender) >= listProductDetail[_productId].price,
            "Insufficient account balance"
        );
        require(
            product.ownerOf(_productId) == address(this),
            "This Product doesn't exist on marketplace"
        );

        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            listProductDetail[_productId].price
        );
        token.transfer(
            listProductDetail[_productId].author,
            (listProductDetail[_productId].price * (100 - feeRate)) / 100
        );

        product.safeTransferFrom(address(this), msg.sender, _productId);
        product.addTransitHistory(_productId, msg.sender);
        emit BuyProduct(
            msg.sender,
            _productId,
            listProductDetail[_productId].price
        );
    }

    function setFeeRate(uint256 _feeRate) public onlyOwner {
        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
    }

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
        emit SetToken(_token);
    }

    function setProduct(Product _product) public onlyOwner {
        product = _product;
        emit SetProduct(_product);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(uint256 amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "Insufficient account balance"
        );
        token.transfer(msg.sender, amount);
    }

    function withdrawErc20() public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
