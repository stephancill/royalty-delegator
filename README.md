# Royalties Delegate

A smart contract for handling payment distribution with automatic royalty calculations and transfers.

## Overview

The Royalties Delegate contract allows users to send payments with specified royalty distributions. The contract automatically calculates and transfers royalties to designated recipients based on basis points, while keeping the remaining funds in the contract.

## Features

- **Automatic Royalty Distribution**: Calculates and transfers royalties based on basis points (1 basis point = 0.01%)
- **Multiple Recipients**: Support for distributing royalties to multiple recipients in a single transaction
- **Flexible Payment**: Accepts payments with custom memos and royalty structures
- **ETH Reception**: Can receive ETH through standard transfers and fallback functions
- **Event Logging**: Comprehensive event emission for payment tracking and transparency

## Contract Structure

### Core Functions

- `initialize()`: Initializes the contract
- `pay(string memo, Royalties[] royalties)`: Processes payments with royalty distribution
- `receive()`: Handles direct ETH transfers
- `fallback()`: Handles ETH transfers with data

### Data Structures

```solidity
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
```

## Usage

### Deploy

```shell
# Set your private key as environment variable
export PRIVATE_KEY=your_private_key_here

# Deploy to a network
forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --broadcast
```

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Gas Snapshots

```shell
forge snapshot
```

### Format Code

```shell
forge fmt
```

## Development

This project uses [Foundry](https://getfoundry.sh/) for development, testing, and deployment.

### Foundry Components

- **Forge**: Ethereum testing framework
- **Cast**: Swiss army knife for interacting with EVM smart contracts
- **Anvil**: Local Ethereum node
- **Chisel**: Fast, utilitarian, and verbose solidity REPL

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## License

MIT
