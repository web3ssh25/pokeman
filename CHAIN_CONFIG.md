# Chain Configuration Guide

This project now uses Foundry's built-in chain configuration instead of passing `--rpc-url` flags. This is similar to Hardhat's network configuration.

## Setup

1. Copy the environment template and fill in your values:
```bash
cp env_template .env
```

2. Fill in your RPC URLs and API keys in the `.env` file:
```bash
# Example RPC URLs (replace with your actual endpoints)
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
POLYGON_RPC_URL=https://polygon-rpc.com

# Example API Keys (replace with your actual keys)
ETHERSCAN_API_KEY=your_etherscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

## Usage

Instead of using `--rpc-url`, now you can use the chain name directly:

### Before (old way):
```bash
forge script script/Deploy.s.sol --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID --broadcast --verify
```

### After (new way):
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

## Available Networks

The following networks are configured in `foundry.toml`:

- **anvil** - Local development (http://localhost:8545)
- **sepolia** - Ethereum testnet
- **goerli** - Ethereum testnet (deprecated)
- **mainnet** - Ethereum mainnet
- **polygon** - Polygon mainnet
- **arbitrum** - Arbitrum One
- **optimism** - Optimism mainnet

## Examples

### Deploy to Sepolia:
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

### Deploy to Polygon:
```bash
forge script script/Deploy.s.sol --rpc-url polygon --broadcast --verify
```

### Run tests on local Anvil:
```bash
forge test --rpc-url anvil
```

### Verify contracts:
```bash
forge verify-contract CONTRACT_ADDRESS src/Contract.sol:Contract --chain sepolia
```

## Adding New Networks

To add a new network, update your `foundry.toml`:

```toml
[rpc_endpoints]
your_network = "${YOUR_NETWORK_RPC_URL}"

[etherscan]
your_network = { key = "${YOUR_NETWORK_API_KEY}" }
```

And add the corresponding environment variables to your `.env` file. 