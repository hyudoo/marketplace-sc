//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SupplyChain.sol";

// import "@openzeppelin/contracts/utils/Address.sol";

contract ProductTransaction is Ownable {
    SupplyChain public productContract;
    uint private _tradeTracker = 0;

    struct Transaction {
        address sender;
        address receiver;
        uint256[] senderTokenIds;
        uint256[] receiverTokenIds;
        bool active;
    }

    constructor(address _productContract) Ownable(msg.sender) {
        productContract = SupplyChain(_productContract);
    }

    function setProductContract(address _productContract) external onlyOwner {
        productContract = SupplyChain(_productContract);
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
                productContract.ownerOf(_senderTokenIds[i]) == msg.sender,
                "You do not own this NFT"
            );
            require(
                productContract.getApproved(_senderTokenIds[i]) ==
                    address(this),
                "Contract is not approved to transfer the NFT"
            );
        }
        for (uint256 i = 0; i < _receiverTokenIds.length; i++) {
            require(
                productContract.ownerOf(_receiverTokenIds[i]) == _receiver,
                "Receiver do not own this NFT"
            );
        }
        for (uint256 i = 0; i < _senderTokenIds.length; i++) {
            productContract.safeTransferFrom(
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
        Transaction storage trade = trades[id];
        require(
            trade.sender == msg.sender,
            "You are not the sender of this trade"
        );
        for (uint256 i = 0; i < trade.senderTokenIds.length; i++) {
            productContract.safeTransferFrom(
                address(this),
                trade.sender,
                trade.senderTokenIds[i]
            );
        }
        trade.active = false;

        emit TransactionCancelled(msg.sender, trade.sender);
    }

    function acceptTrade(
        uint256 _tokenId
    ) external payable tradeExists(_tokenId) {
        Transaction storage trade = trades[_tokenId];
        require(trade.receiver == msg.sender, "Transaction already completed");
        for (uint256 i = 0; i < trade.receiverTokenIds.length; i++) {
            require(
                productContract.ownerOf(trade.receiverTokenIds[i]) ==
                    msg.sender,
                "Receiver do not own this NFT"
            );
        }

        for (uint256 i = 0; i < trade.senderTokenIds.length; i++) {
            productContract.safeTransferFrom(
                address(this),
                trade.receiver,
                trade.senderTokenIds[i]
            );
        }
        for (uint256 i = 0; i < trade.receiverTokenIds.length; i++) {
            productContract.safeTransferFrom(
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

    modifier tradeExists(uint256 tokenId) {
        require(trades[tokenId].active, "Transaction does not exist");
        _;
    }
}
