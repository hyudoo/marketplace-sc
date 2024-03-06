// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SupplyChain {
    struct Product {
        uint256 id;
        string name;
        string image;
        address manufacturer;
        address[] transitHistory;
        address owner;
        bool isDelivered;
    }

    mapping(uint256 => Product) public products;
    uint256 public productCount = 0;

    event ProductCreated(
        uint256 id,
        string name,
        string image,
        address manufacturer
    );
    event ProductTransferred(uint256 id, address from, address to);
    event ProductDelivered(uint256 id, address owner);

    function createProduct(string memory _name, string memory _image) public {
        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _image,
            msg.sender,
            new address[](0),
            msg.sender,
            false
        );
        emit ProductCreated(productCount, _name, _image, msg.sender);
    }

    function transferProduct(uint256 _id, address _to) public {
        require(products[_id].id > 0, "Product does not exist");
        require(
            products[_id].owner == msg.sender,
            "You are not the owner of this product"
        );
        require(
            products[_id].isDelivered == false,
            "Product has already been delivered"
        );

        products[_id].transitHistory.push(_to);
        emit ProductTransferred(_id, msg.sender, _to);
    }

    function deliverProduct(uint256 _id) public {
        require(products[_id].id != 0, "Product does not exist");
        require(
            products[_id].owner != msg.sender,
            "You are not the owner of this product"
        );
        require(
            products[_id].isDelivered == false,
            "Product has already been delivered"
        );

        products[_id].owner = msg.sender;
        products[_id].isDelivered = true;
        emit ProductDelivered(_id, msg.sender);
    }
}
