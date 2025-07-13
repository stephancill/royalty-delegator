// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Delegation, Royalties, Payment} from "../src/Contract.sol";

// Helper contract for payment failure
contract Rejector {
    receive() external payable {
        revert("fail");
    }
}

contract DelegationTest is Test {
    Delegation public delegation;

    // Test addresses
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public david = makeAddr("david");

    // Test amounts
    uint256 public constant PAYMENT_AMOUNT = 1 ether;
    uint256 public constant ROYALTY_BASIS_POINTS = 1000; // 10%
    uint256 public constant ROYALTY_AMOUNT =
        (PAYMENT_AMOUNT * ROYALTY_BASIS_POINTS) / 10000; // 0.1 ether

    function setUp() public {
        delegation = new Delegation();
        vm.label(address(delegation), "Delegation");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(david, "David");
    }

    // ============ Initialization Tests ============

    function test_Initialize() public {
        vm.expectEmit(true, true, true, true);
        emit Delegation.Initialized();
        delegation.initialize();
    }

    function test_InitializeCanBeCalledMultipleTimes() public {
        delegation.initialize();
        delegation.initialize(); // Should not revert
    }

    // ============ ETH Receiving Tests ============

    function test_ReceiveETH() public {
        uint256 amount = 1 ether;
        vm.deal(alice, amount);
        vm.expectEmit(true, true, true, true);
        emit Delegation.ETHReceived(alice, amount, "");
        vm.prank(alice);
        (bool success, ) = address(delegation).call{value: amount}("");
        assertTrue(success);
        assertEq(address(delegation).balance, amount);
    }

    function test_FallbackWithData() public {
        uint256 amount = 0.5 ether;
        bytes memory data = "test data";
        vm.deal(alice, amount);
        vm.expectEmit(true, true, true, true);
        emit Delegation.ETHReceived(alice, amount, data);
        vm.prank(alice);
        (bool success, ) = address(delegation).call{value: amount}(data);
        assertTrue(success);
        assertEq(address(delegation).balance, amount);
    }

    // ============ Payment Tests ============

    function test_PayWithSingleRoyalty() public {
        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: ROYALTY_BASIS_POINTS
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment",
            amount: PAYMENT_AMOUNT,
            royalties: royalties
        });

        uint256 bobBalanceBefore = bob.balance;

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: PAYMENT_AMOUNT}("Test payment", royalties);

        assertEq(bob.balance, bobBalanceBefore + ROYALTY_AMOUNT);
        assertEq(address(delegation).balance, PAYMENT_AMOUNT - ROYALTY_AMOUNT);
    }

    function test_PayWithMultipleRoyalties() public {
        Royalties[] memory royalties = new Royalties[](2);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 500 // 5%
        });
        royalties[1] = Royalties({
            receiver: charlie,
            basisPoints: 300 // 3%
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with multiple royalties",
            amount: PAYMENT_AMOUNT,
            royalties: royalties
        });

        uint256 bobBalanceBefore = bob.balance;
        uint256 charlieBalanceBefore = charlie.balance;

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: PAYMENT_AMOUNT}(
            "Test payment with multiple royalties",
            royalties
        );

        uint256 bobRoyalty = (PAYMENT_AMOUNT * 500) / 10000; // 0.05 ether
        uint256 charlieRoyalty = (PAYMENT_AMOUNT * 300) / 10000; // 0.03 ether

        assertEq(bob.balance, bobBalanceBefore + bobRoyalty);
        assertEq(charlie.balance, charlieBalanceBefore + charlieRoyalty);
        assertEq(
            address(delegation).balance,
            PAYMENT_AMOUNT - bobRoyalty - charlieRoyalty
        );
    }

    function test_PayWithNoRoyalties() public {
        Royalties[] memory royalties = new Royalties[](0);

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with no royalties",
            amount: PAYMENT_AMOUNT,
            royalties: royalties
        });

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: PAYMENT_AMOUNT}(
            "Test payment with no royalties",
            royalties
        );

        // All ETH should remain in the contract
        assertEq(address(delegation).balance, PAYMENT_AMOUNT);
    }

    function test_PayWithExactBalance() public {
        uint256 paymentAmount = 1 ether;

        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 10000 // 100% - exact balance
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with exact balance",
            amount: paymentAmount,
            royalties: royalties
        });

        uint256 bobBalanceBefore = bob.balance;

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: paymentAmount}(
            "Test payment with exact balance",
            royalties
        );

        assertEq(bob.balance, bobBalanceBefore + paymentAmount);
        assertEq(address(delegation).balance, 0);
    }

    function test_PayWithExactPaymentValue() public {
        uint256 paymentAmount = 1 ether;

        Royalties[] memory royalties = new Royalties[](2);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 6000 // 60%
        });
        royalties[1] = Royalties({
            receiver: charlie,
            basisPoints: 4000 // 40% - total 100%
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with exact 100% royalties",
            amount: paymentAmount,
            royalties: royalties
        });

        uint256 bobBalanceBefore = bob.balance;
        uint256 charlieBalanceBefore = charlie.balance;

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: paymentAmount}(
            "Test payment with exact 100% royalties",
            royalties
        );

        uint256 bobRoyalty = (paymentAmount * 6000) / 10000; // 0.6 ether
        uint256 charlieRoyalty = (paymentAmount * 4000) / 10000; // 0.4 ether

        assertEq(bob.balance, bobBalanceBefore + bobRoyalty);
        assertEq(charlie.balance, charlieBalanceBefore + charlieRoyalty);
        assertEq(address(delegation).balance, 0);
    }

    // ============ Error Handling Tests ============

    function test_RevertWhenRoyaltiesExceedPaymentValue() public {
        uint256 paymentAmount = 1 ether;

        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 10001 // 100.01% - exceeds payment value
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with excessive royalties",
            amount: paymentAmount,
            royalties: royalties
        });

        vm.expectRevert(Delegation.InvalidRoyalties.selector);
        delegation.pay{value: paymentAmount}(
            "Test payment with excessive royalties",
            royalties
        );
    }

    function test_RevertWhenMultipleRoyaltiesExceedPaymentValue() public {
        uint256 paymentAmount = 1 ether;

        Royalties[] memory royalties = new Royalties[](2);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 6000 // 60%
        });
        royalties[1] = Royalties({
            receiver: charlie,
            basisPoints: 5000 // 50% - total 110%
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with multiple excessive royalties",
            amount: paymentAmount,
            royalties: royalties
        });

        vm.expectRevert(Delegation.InvalidRoyalties.selector);
        delegation.pay{value: paymentAmount}(
            "Test payment with multiple excessive royalties",
            royalties
        );
    }

    function test_RevertWhenPaymentFails() public {
        // Deploy a contract that will reject payments
        Rejector rejector = new Rejector();
        uint256 paymentAmount = 1 ether;
        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: address(rejector),
            basisPoints: 1000 // 10%
        });
        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment that fails",
            amount: paymentAmount,
            royalties: royalties
        });
        vm.expectRevert(bytes("Payment failed"));
        delegation.pay{value: paymentAmount}(
            "Test payment that fails",
            royalties
        );
    }

    // ============ Edge Cases ============

    function test_PayWithZeroAmount() public {
        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 1000 // 10%
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with zero amount",
            amount: 0,
            royalties: royalties
        });

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: 0}("Test payment with zero amount", royalties);

        // No royalties should be paid
        assertEq(bob.balance, 0);
    }

    function test_PayWithZeroBasisPoints() public {
        uint256 paymentAmount = 1 ether;

        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 0 // 0%
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with zero basis points",
            amount: paymentAmount,
            royalties: royalties
        });

        uint256 bobBalanceBefore = bob.balance;

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: paymentAmount}(
            "Test payment with zero basis points",
            royalties
        );

        // No royalties should be paid
        assertEq(bob.balance, bobBalanceBefore);
        assertEq(address(delegation).balance, paymentAmount);
    }

    function test_PayWithMaxBasisPoints() public {
        uint256 paymentAmount = 1 ether;

        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: 10000 // 100%
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Test payment with max basis points",
            amount: paymentAmount,
            royalties: royalties
        });

        uint256 bobBalanceBefore = bob.balance;

        vm.expectEmit(true, true, true, true);
        emit Delegation.PaymentReceived(payment);

        delegation.pay{value: paymentAmount}(
            "Test payment with max basis points",
            royalties
        );

        assertEq(bob.balance, bobBalanceBefore + paymentAmount);
        assertEq(address(delegation).balance, 0);
    }

    // ============ Gas Optimization Tests ============

    function test_GasUsageForSingleRoyalty() public {
        Royalties[] memory royalties = new Royalties[](1);
        royalties[0] = Royalties({
            receiver: bob,
            basisPoints: ROYALTY_BASIS_POINTS
        });

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Gas test payment",
            amount: PAYMENT_AMOUNT,
            royalties: royalties
        });

        uint256 gasBefore = gasleft();
        delegation.pay{value: PAYMENT_AMOUNT}("Gas test payment", royalties);
        uint256 gasUsed = gasBefore - gasleft();

        // Log gas usage for reference
        console.log("Gas used for single royalty payment:", gasUsed);
    }

    function test_GasUsageForMultipleRoyalties() public {
        Royalties[] memory royalties = new Royalties[](5);
        for (uint256 i = 0; i < 5; i++) {
            royalties[i] = Royalties({
                receiver: makeAddr(string(abi.encodePacked("receiver", i))),
                basisPoints: 1000 // 10% each
            });
        }

        Payment memory payment = Payment({
            receiver: address(delegation),
            memo: "Gas test payment with multiple royalties",
            amount: PAYMENT_AMOUNT,
            royalties: royalties
        });

        uint256 gasBefore = gasleft();
        delegation.pay{value: PAYMENT_AMOUNT}(
            "Gas test payment with multiple royalties",
            royalties
        );
        uint256 gasUsed = gasBefore - gasleft();

        // Log gas usage for reference
        console.log("Gas used for multiple royalties payment:", gasUsed);
    }
}
