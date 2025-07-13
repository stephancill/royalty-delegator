// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Royalties {
    address receiver;
    uint256 basisPoints;
}
struct Payment {
    address receiver;
    string memo;
    uint256 amount;
    Royalties[] royalties;
}

contract Delegation {
    event ETHReceived(address indexed from, uint256 indexed amount, bytes data);
    event PaymentReceived(Payment payment);
    event Initialized();

    error InvalidRoyalties();

    function initialize() external {
        emit Initialized();
    }

    function pay(
        string calldata memo,
        Royalties[] calldata royalties
    ) external payable {
        uint256 amountSent = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            address receiver = royalties[i].receiver;
            uint256 basisPoints = royalties[i].basisPoints;
            uint256 amount = (msg.value * basisPoints) / 10000;
            amountSent += amount;

            if (amountSent > msg.value) {
                revert InvalidRoyalties();
            }

            (bool success, ) = payable(receiver).call{value: amount}("");
            require(success, "Payment failed");
        }

        Payment memory payment = Payment({
            receiver: address(this),
            memo: memo,
            amount: msg.value,
            royalties: royalties
        });
        emit PaymentReceived(payment);
    }

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value, "");
    }

    fallback() external payable {
        emit ETHReceived(msg.sender, msg.value, msg.data);
    }
}
