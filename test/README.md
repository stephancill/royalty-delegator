# Delegation Contract Test Suite

This directory contains comprehensive tests for the `Delegation` contract using Foundry.

## Test Structure

### `Delegation.t.sol`

The main test file containing comprehensive tests for all contract functionality:

#### Test Categories:

1. **Initialization Tests**

   - `test_Initialize()` - Tests the initialize function
   - `test_InitializeCanBeCalledMultipleTimes()` - Verifies initialize can be called multiple times

2. **ETH Receiving Tests**

   - `test_ReceiveETH()` - Tests basic ETH receiving via `receive()` function
   - `test_FallbackWithData()` - Tests fallback function with data

3. **Payment Tests**

   - `test_PayWithSingleRoyalty()` - Tests payment with one royalty recipient
   - `test_PayWithMultipleRoyalties()` - Tests payment with multiple royalty recipients
   - `test_PayWithNoRoyalties()` - Tests payment with no royalties
   - `test_PayWithExactBalance()` - Tests payment that uses exact contract balance

4. **Error Handling Tests**

   - `test_RevertWhenRoyaltiesExceedBalance()` - Tests revert when royalties exceed available balance
   - `test_RevertWhenMultipleRoyaltiesExceedBalance()` - Tests revert with multiple excessive royalties
   - `test_RevertWhenPaymentFails()` - Tests revert when external payment fails

5. **Edge Cases**

   - `test_PayWithZeroAmount()` - Tests payment with zero amount
   - `test_PayWithZeroBasisPoints()` - Tests payment with zero basis points
   - `test_PayWithMaxBasisPoints()` - Tests payment with maximum basis points (100%)

6. **Gas Optimization Tests**
   - `test_GasUsageForSingleRoyalty()` - Measures gas usage for single royalty
   - `test_GasUsageForMultipleRoyalties()` - Measures gas usage for multiple royalties

## Running Tests

### Run all tests:

```bash
forge test
```

### Run specific test:

```bash
forge test --match-test test_PayWithSingleRoyalty
```

### Run tests with verbose output:

```bash
forge test -vv
```

### Run tests with gas reporting:

```bash
forge test --gas-report
```

### Run tests and generate coverage:

```bash
forge coverage
```

## Test Utilities

The test suite includes several utilities:

- **Test Addresses**: Pre-defined addresses (alice, bob, charlie, david) for consistent testing
- **Constants**: Pre-defined amounts and basis points for royalty calculations
- **Setup**: Automatic contract deployment and address labeling in `setUp()`

## Key Test Scenarios Covered

1. **Royalty Calculations**: Tests various basis point combinations and calculations
2. **Balance Management**: Ensures contract balance is properly managed during payments
3. **Error Conditions**: Tests all revert conditions and error messages
4. **Event Emissions**: Verifies all events are emitted correctly
5. **Gas Efficiency**: Measures gas usage for optimization purposes

## Contract Functions Tested

- `initialize()` - Contract initialization
- `pay(Payment calldata payment)` - Main payment function with royalties
- `receive()` - ETH receiving function
- `fallback()` - Fallback function for calls with data

## Error Types Tested

- `InvalidRoyalties` - When royalty amounts exceed contract balance
- `Payment failed` - When external payment calls fail

## Events Tested

- `Initialized()` - Emitted on contract initialization
- `ETHReceived(address indexed from, uint256 indexed amount, bytes data)` - Emitted when ETH is received
- `PaymentReceived(Payment payment)` - Emitted when payment is processed
