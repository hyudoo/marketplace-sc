//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./Product.sol";

contract ExchangeProduct is IERC721Receiver, Ownable {
    Product public product;
    uint private _tracker = 0;

    struct ExchangeInfo {
        address sender;
        address receiver;
        uint256[] senderProductIds;
        uint256[] receiverProductIds;
        bool active;
    }

    constructor(Product _product) Ownable(msg.sender) {
        product = _product;
    }

    mapping(uint256 => ExchangeInfo) public exchanges;

    event ExchangeCreated(
        address indexed sender,
        address indexed receiver,
        uint256[] senderProductIds,
        uint256[] receiverProductIds
    );

    event ExchangeCancelled(address indexed sender, address indexed receiver);

    event ExchangeSuccessful(
        address indexed sender,
        address indexed receiver,
        uint256[] senderProductIds,
        uint256[] receiverProductIds
    );

    function createExchange(
        address _receiver,
        uint256[] memory _senderProductIds,
        uint256[] memory _receiverProductIds
    ) public {
        require(
            _senderProductIds.length > 0 || _receiverProductIds.length > 0,
            "Exchange cannot not be empty"
        );
        for (uint256 i = 0; i < _senderProductIds.length; i++) {
            require(
                product.ownerOf(_senderProductIds[i]) == msg.sender,
                "You do not own this NFT"
            );
            require(
                product.getApproved(_senderProductIds[i]) == address(this),
                "Contract is not approved to transfer the NFT"
            );
        }
        for (uint256 i = 0; i < _receiverProductIds.length; i++) {
            require(
                product.ownerOf(_receiverProductIds[i]) == _receiver,
                "Receiver do not own this NFT"
            );
        }
        for (uint256 i = 0; i < _senderProductIds.length; i++) {
            product.safeTransferFrom(
                msg.sender,
                address(this),
                _senderProductIds[i]
            );
        }
        _tracker = _tracker + 1;
        exchanges[_tracker] = ExchangeInfo({
            sender: msg.sender,
            receiver: _receiver,
            senderProductIds: _senderProductIds,
            receiverProductIds: _receiverProductIds,
            active: true
        });

        emit ExchangeCreated(
            msg.sender,
            _receiver,
            _senderProductIds,
            _receiverProductIds
        );
    }

    function cancelExchange(
        uint256 _exchangeId
    ) public exchangeExists(_exchangeId) {
        ExchangeInfo storage exchange = exchanges[_exchangeId];
        require(
            msg.sender == exchange.sender || msg.sender == exchange.receiver,
            "You are not a person of this exchange"
        );
        for (uint256 i = 0; i < exchange.senderProductIds.length; i++) {
            product.safeTransferFrom(
                address(this),
                exchange.sender,
                exchange.senderProductIds[i]
            );
        }
        exchanges[_exchangeId].active = false;

        emit ExchangeCancelled(exchange.sender, exchange.receiver);
    }

    function acceptExchange(
        uint256 _exchangeId
    ) public exchangeExists(_exchangeId) {
        ExchangeInfo storage exchange = exchanges[_exchangeId];
        require(
            exchange.receiver == msg.sender,
            "Only receiver can accept exchange"
        );
        for (uint256 i = 0; i < exchange.receiverProductIds.length; i++) {
            require(
                product.ownerOf(exchange.receiverProductIds[i]) == msg.sender,
                "Receiver do not own this NFT"
            );
            require(
                product.getApproved(exchange.receiverProductIds[i]) ==
                    address(this),
                "Contract is not approved to transfer the NFT"
            );
        }

        for (uint256 i = 0; i < exchange.senderProductIds.length; i++) {
            require(
                product.ownerOf(exchange.senderProductIds[i]) == address(this),
                "Exchange do not own this NFT"
            );
        }

        for (uint256 i = 0; i < exchange.senderProductIds.length; i++) {
            product.safeTransferFrom(
                address(this),
                exchange.receiver,
                exchange.senderProductIds[i]
            );
            product.addTransitHistory(
                exchange.senderProductIds[i],
                exchange.receiver
            );
        }
        for (uint256 i = 0; i < exchange.receiverProductIds.length; i++) {
            product.safeTransferFrom(
                msg.sender,
                exchange.sender,
                exchange.receiverProductIds[i]
            );
            product.addTransitHistory(
                exchange.receiverProductIds[i],
                exchange.sender
            );
        }
        exchanges[_exchangeId].active = false;

        emit ExchangeSuccessful(
            exchange.sender,
            msg.sender,
            exchange.senderProductIds,
            exchange.receiverProductIds
        );
    }

    function getExchangeById(
        uint256 _exchangeId
    ) public view exchangeExists(_exchangeId) returns (ExchangeInfo memory) {
        return exchanges[_exchangeId];
    }

    function getSendExchange(
        address _sender
    ) external view returns (uint256[] memory) {
        uint256 length = 0;
        for (uint256 i = 1; i <= _tracker; i++) {
            if (exchanges[i].sender == _sender && exchanges[i].active) {
                length++;
            }
        }
        uint256[] memory sendExchanges = new uint256[](length);
        uint256 count = 0;
        for (uint256 i = 1; i <= _tracker; i++) {
            if (exchanges[i].sender == _sender && exchanges[i].active) {
                sendExchanges[count] = i;
                count++;
            }
        }
        return sendExchanges;
    }

    function getReceiveExchange(
        address _sender
    ) external view returns (uint256[] memory) {
        uint256 length = 0;
        for (uint256 i = 1; i <= _tracker; i++) {
            if (exchanges[i].receiver == _sender && exchanges[i].active) {
                length++;
            }
        }
        uint256[] memory receiveExchanges = new uint256[](length);
        uint256 count = 0;
        for (uint256 i = 1; i <= _tracker; i++) {
            if (exchanges[i].receiver == _sender && exchanges[i].active) {
                receiveExchanges[count] = i;
                count++;
            }
        }
        return receiveExchanges;
    }

    function setProduct(Product _product) external onlyOwner {
        product = _product;
    }

    modifier exchangeExists(uint256 _exchangeId) {
        require(exchanges[_exchangeId].active, "Exchange does not exist");
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
