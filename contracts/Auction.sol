//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Product.sol";

contract Auction is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    Product private product;
    IERC20 private token;

    uint public constant FEE_RATE = 5; // Percentage

    uint public constant MINIMUM_BID_RATE = 110; // Percentage

    constructor(IERC20 _token, Product _product) Ownable(msg.sender) {
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
        uint256 initialPrice;
        uint256 productId;
        uint256 lastBid;
        address lastBidder;
        uint256 startTime;
        uint256 endTime;
    }

    event AuctionCreated(
        address indexed author,
        uint256 indexed _productId,
        uint256 initialPrice,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionJoined(
        address indexed author,
        uint256 indexed _productId,
        uint256 lastBid,
        address lastBidder
    );

    event AuctionFinished(
        address indexed author,
        uint256 indexed _productId,
        uint256 lastBid,
        address lastBidder
    );

    event AuctionCanceled(address indexed author, uint256 indexed _productId);
    event SetToken(IERC20 _token);
    event SetProduct(Product _product);

    mapping(uint256 => AuctionInfo) auctions;

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

        auctions[_productId] = AuctionInfo(
            msg.sender,
            _initialPrice,
            _productId,
            _initialPrice,
            address(0),
            _startTime,
            _endTime
        );
        emit AuctionCreated(
            msg.sender,
            _productId,
            _initialPrice,
            _startTime,
            _endTime
        );
    }

    function joinAuction(uint256 _productId, uint256 _bid) public {
        AuctionInfo memory _auction = auctions[_productId];

        require(
            block.timestamp >= _auction.startTime,
            "Auction has not started"
        );
        require(
            _auction.lastBidder != msg.sender,
            "You have already bid on this auction"
        );

        uint256 _minBid = _auction.lastBidder == address(0)
            ? _auction.initialPrice
            : (_auction.lastBid * MINIMUM_BID_RATE) / 100;

        require(
            _bid >= _minBid,
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

        auctions[_productId].lastBidder = msg.sender;
        auctions[_productId].lastBid = _bid;

        emit AuctionJoined(_auction.author, _productId, _bid, msg.sender);
    }

    function finishAuction(
        uint256 _productId
    ) public onlyAuctioneer(_productId) {
        AuctionInfo memory _auction = auctions[_productId];

        product.safeTransferFrom(
            address(this),
            _auction.lastBidder,
            _productId
        );

        uint256 lastBid = _auction.lastBid;
        uint256 profit = _auction.lastBid - _auction.initialPrice;

        uint256 auctionServiceFee = (profit * FEE_RATE) / 100;

        uint256 auctioneerReceive = lastBid - auctionServiceFee;

        token.transfer(_auction.author, auctioneerReceive);
        product.addTransitHistory(_productId, _auction.lastBidder);
        emit AuctionFinished(
            _auction.author,
            _productId,
            lastBid,
            _auction.lastBidder
        );
    }

    function cancelAuction(
        uint256 _productId
    ) public onlyAuctioneer(_productId) {
        product.safeTransferFrom(
            address(this),
            auctions[_productId].author,
            _productId
        );

        if (auctions[_productId].lastBidder != address(0)) {
            token.transfer(
                auctions[_productId].lastBidder,
                auctions[_productId].lastBid
            );
        }

        emit AuctionCanceled(auctions[_productId].author, _productId);
    }

    function getAuctionById(
        uint256 _productId
    ) public view returns (AuctionInfo memory) {
        return auctions[_productId];
    }

    function getAuctions() public view returns (AuctionInfo[] memory) {
        uint balance = product.balanceOf(address(this));
        AuctionInfo[] memory myProduct = new AuctionInfo[](balance);

        for (uint i = 0; i < balance; i++) {
            myProduct[i] = auctions[
                product.tokenOfOwnerByIndex(address(this), i)
            ];
        }
        return myProduct;
    }

    modifier onlyAuctioneer(uint256 _productId) {
        require(
            (msg.sender == auctions[_productId].author ||
                msg.sender == owner()),
            "Only auctioneer or owner can perform this action"
        );
        _;
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
}
