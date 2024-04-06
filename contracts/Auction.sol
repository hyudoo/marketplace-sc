//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SupplyChain.sol";

contract Auction is IERC721Receiver, Ownable {
    SupplyChain private product;
    IERC20 private token;

    uint public constant AUCTION_SERVICE_FEE_RATE = 5; // Percentage

    uint public constant MINIMUM_BID_RATE = 110; // Percentage

    constructor(IERC20 _token, SupplyChain _product) Ownable(msg.sender) {
        token = _token;
        product = _product;
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

    struct AuctionInfo {
        address author;
        uint256 _productId;
        uint256 initialPrice;
        address previousBidder;
        uint256 lastBid;
        address lastBidder;
        uint256 startTime;
        uint256 endTime;
        bool completed;
        uint256 auctionId;
    }

    AuctionInfo[] private auction;

    function createAuction(
        uint256 _productId,
        uint256 _initialPrice,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        require(block.timestamp <= _startTime, "Auction can not start");
        require(_startTime < _endTime, "Auction can not end before it starts");
        require(0 < _initialPrice, "Initial price must be greater than 0");

        require(
            product.ownerOf(_productId) == msg.sender,
            "Must stake your own product"
        );
        require(
            product.getApproved(_productId) == address(this),
            "This contract must be approved to transfer the product"
        );

        product.safeTransferFrom(msg.sender, address(this), _productId);

        AuctionInfo memory _auction = AuctionInfo(
            msg.sender,
            _productId,
            _initialPrice,
            address(0),
            _initialPrice,
            address(0),
            _startTime,
            _endTime,
            false,
            auction.length
        );

        auction.push(_auction);
    }

    function joinAuction(uint256 _auctionId, uint256 _bid) public {
        AuctionInfo memory _auction = auction[_auctionId];

        require(
            block.timestamp >= _auction.startTime,
            "Auction has not started"
        );
        require(
            _auction.lastBidder != msg.sender,
            "You have already bid on this auction"
        );
        require(_auction.completed == false, "Auction is already completed");

        uint256 _minBid = _auction.lastBidder == address(0)
            ? _auction.initialPrice
            : (_auction.lastBid * MINIMUM_BID_RATE) / 100;

        require(
            _minBid <= _bid,
            "Bid price must be greater than the minimum price"
        );

        require(token.balanceOf(msg.sender) >= _bid, "Insufficient balance");
        require(
            token.allowance(msg.sender, address(this)) >= _bid,
            "Insufficient allowance"
        );

        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _bid);

        if (_auction.lastBidder != address(0)) {
            token.transfer(_auction.lastBidder, _auction.lastBid);
        }

        auction[_auctionId].previousBidder = _auction.lastBidder;
        auction[_auctionId].lastBidder = msg.sender;
        auction[_auctionId].lastBid = _bid;
    }

    function finishAuction(
        uint256 _auctionId
    ) public onlyAuctioneer(_auctionId) {
        require(
            auction[_auctionId].completed == false,
            "Auction is already completed"
        );

        product.safeTransferFrom(
            address(this),
            auction[_auctionId].lastBidder,
            auction[_auctionId]._productId
        );

        uint256 lastBid = auction[_auctionId].lastBid;
        uint256 profit = auction[_auctionId].lastBid -
            auction[_auctionId].initialPrice;

        uint256 auctionServiceFee = (profit * AUCTION_SERVICE_FEE_RATE) / 100;

        uint256 auctioneerReceive = lastBid - auctionServiceFee;

        token.transfer(auction[_auctionId].author, auctioneerReceive);

        auction[_auctionId].completed = true;
    }

    function cancelAuction(
        uint256 _auctionId
    ) public onlyAuctioneer(_auctionId) {
        require(
            auction[_auctionId].completed == false,
            "Auction is already completed"
        );

        product.safeTransferFrom(
            address(this),
            auction[_auctionId].author,
            auction[_auctionId]._productId
        );

        if (auction[_auctionId].lastBidder != address(0)) {
            token.transfer(
                auction[_auctionId].lastBidder,
                auction[_auctionId].lastBid
            );
        }
        auction[_auctionId].completed = true;
    }

    function getAuction(
        uint256 _auctionId
    ) public view returns (AuctionInfo memory) {
        return auction[_auctionId];
    }

    function getAuctionByStatus(
        bool _isCompleted
    ) public view returns (AuctionInfo[] memory) {
        uint length = 0;
        for (uint i = 0; i < auction.length; i++) {
            if (auction[i].completed == _isCompleted) {
                length++;
            }
        }

        AuctionInfo[] memory results = new AuctionInfo[](length);
        uint j = 0;
        for (uint256 index = 0; index < auction.length; index++) {
            if (auction[index].completed == _isCompleted) {
                results[j] = auction[index];
                j++;
            }
        }
        return results;
    }

    modifier onlyAuctioneer(uint256 _auctionId) {
        require(
            (msg.sender == auction[_auctionId].author || msg.sender == owner()),
            "Only auctioneer or owner can perform this action"
        );
        _;
    }
}
