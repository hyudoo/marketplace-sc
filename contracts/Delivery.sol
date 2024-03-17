//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./SupplyChain.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract DeliveryContract is Ownable, AccessControlEnumerable {
    SupplyChain public supplyChain;

    enum DeliveryStatus {
        Pending,
        Delivered
    }

    struct DeliveryData {
        address seller;
        address deliveryPerson;
        string cid;
        DeliveryStatus delivery;
    }

    mapping(address => DeliveryData) public purchaseHistory;
    uint256[] public deliveryList;

    constructor() Ownable(msg.sender) {}

    // write function to confirm delivery of product and update status in mapping
    // function addToDeliveryList(string memory cid) external {
    //     require(
    //         purchaseHistory[msg.sender].seller != address(0),
    //         "Only buyer can add to delivery list"
    //     );
    //     require(
    //         purchaseHistory[msg.sender].delivery == DeliveryStatus.Pending,
    //         "Delivery is not authorized yet"
    //     );
    // }

    function setSupplyChainAddress(address _supplyChain) external onlyOwner {
        supplyChain = SupplyChain(_supplyChain);
    }

    function confirmDelivery(address _buyer) external onlyOwner {
        require(
            purchaseHistory[_buyer].seller != address(0),
            "Only buyer can confirm delivery"
        );
        require(
            purchaseHistory[_buyer].delivery == DeliveryStatus.Pending,
            "Delivery is not authorized yet"
        );
        purchaseHistory[_buyer].delivery = DeliveryStatus.Delivered;
    }

    function getSoldProduct(
        uint256 tokenId
    ) external view returns (string memory) {
        return supplyChain.getCID(tokenId);
    }

    function buyToken(uint256 tokenId) external {
        require(
            purchaseHistory[msg.sender].seller == address(0),
            "You have already purchased a product"
        );
        purchaseHistory[msg.sender] = DeliveryData(
            supplyChain.ownerOf(tokenId),
            address(0),
            supplyChain.getCID(tokenId),
            DeliveryStatus.Pending
        );
    }

    // @dev: This method will be called by the delivery person to confirm delivery of the product
}
