//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./SupplyChain.sol";

// import "@openzeppelin/contracts/utils/Address.sol";

contract ExchangeProduct is IERC721Receiver, Ownable {
    SupplyChain public product;
    uint private _tradeTracker = 0;

    struct Transaction {
        address sender;
        address receiver;
        uint256[] senderTokenIds;
        uint256[] receiverTokenIds;
        bool active;
    }

    constructor(SupplyChain _product) Ownable(msg.sender) {
        product = _product;
    }

    function setProductContract(SupplyChain _product) external onlyOwner {
        product = _product;
    }

    mapping(uint256 => Transaction) public trades;

    event TransactionCreated(
        address indexed sender,
        address indexed receiver,
        uint256[] senderTokenIds,
        uint256[] receiverTokenIds
    );
    event TransactionCancelled(
        address indexed sender,
        address indexed receiver
    );
    event TransactionSuccessful(
        address indexed sender,
        address indexed receiver,
        uint256[] senderTokenIds,
        uint256[] receiverTokenIds
    );

    function createTransaction(
        address _receiver,
        uint256[] memory _senderTokenIds,
        uint256[] memory _receiverTokenIds
    ) external {
        require(
            _senderTokenIds.length > 0 || _receiverTokenIds.length > 0,
            "Transaction cannot not be empty"
        );
        for (uint256 i = 0; i < _senderTokenIds.length; i++) {
            require(
                product.ownerOf(_senderTokenIds[i]) == msg.sender,
                "You do not own this NFT"
            );
            require(
                product.getApproved(_senderTokenIds[i]) == address(this),
                "Contract is not approved to transfer the NFT"
            );
        }
        for (uint256 i = 0; i < _receiverTokenIds.length; i++) {
            require(
                product.ownerOf(_receiverTokenIds[i]) == _receiver,
                "Receiver do not own this NFT"
            );
        }
        for (uint256 i = 0; i < _senderTokenIds.length; i++) {
            product.safeTransferFrom(
                msg.sender,
                address(this),
                _senderTokenIds[i]
            );
        }
        _tradeTracker = _tradeTracker + 1;
        trades[_tradeTracker] = Transaction({
            sender: msg.sender,
            receiver: _receiver,
            senderTokenIds: _senderTokenIds,
            receiverTokenIds: _receiverTokenIds,
            active: true
        });

        emit TransactionCreated(
            msg.sender,
            _receiver,
            _senderTokenIds,
            _receiverTokenIds
        );
    }

    function cancelTransaction(uint256 id) external tradeExists(id) {
        Transaction memory trade = trades[id];
        require(
            trade.sender == msg.sender || msg.sender == trade.receiver,
            "You are not a person of this trade"
        );
        for (uint256 i = 0; i < trade.senderTokenIds.length; i++) {
            product.safeTransferFrom(
                address(this),
                trade.sender,
                trade.senderTokenIds[i]
            );
        }
        trade.active = false;

        emit TransactionCancelled(trade.sender, trade.receiver);
    }

    function acceptTrade(
        uint256 _tokenId
    ) external payable tradeExists(_tokenId) {
        Transaction memory trade = trades[_tokenId];
        require(trade.receiver == msg.sender, "Only receiver can accept trade");
        for (uint256 i = 0; i < trade.receiverTokenIds.length; i++) {
            require(
                product.ownerOf(trade.receiverTokenIds[i]) == msg.sender,
                "Receiver do not own this NFT"
            );
            require(
                product.getApproved(trade.receiverTokenIds[i]) == trade.sender,
                "Contract is not approved to transfer the NFT"
            );
        }

        for (uint256 i = 0; i < trade.senderTokenIds.length; i++) {
            product.safeTransferFrom(
                address(this),
                trade.receiver,
                trade.senderTokenIds[i]
            );
        }
        for (uint256 i = 0; i < trade.receiverTokenIds.length; i++) {
            product.safeTransferFrom(
                trade.receiver,
                trade.sender,
                trade.receiverTokenIds[i]
            );
        }
        trade.active = false;

        emit TransactionSuccessful(
            trade.sender,
            msg.sender,
            trade.senderTokenIds,
            trade.receiverTokenIds
        );
    }

    function getTradeById(
        uint256 id
    ) external view tradeExists(id) returns (Transaction memory) {
        return trades[id];
    }

    function getTradeBySender(
        address _sender
    ) external view returns (uint256[] memory) {
        uint256[] memory senderTrades = new uint256[](_tradeTracker);
        uint256 count = 0;
        for (uint256 i = 0; i < _tradeTracker; i++) {
            if (trades[i].sender == _sender && trades[i].active) {
                senderTrades[count] = i;
                count++;
            }
        }
        return senderTrades;
    }

    function getTradeByReceiver(
        address _sender
    ) external view returns (uint256[] memory) {
        uint256[] memory receiverTrades = new uint256[](_tradeTracker);
        uint256 count = 0;
        for (uint256 i = 0; i < _tradeTracker; i++) {
            if (trades[i].receiver == _sender && trades[i].active) {
                receiverTrades[count] = i;
                count++;
            }
        }
        return receiverTrades;
    }

    modifier tradeExists(uint256 tokenId) {
        require(trades[tokenId].active, "Transaction does not exist");
        _;
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
