# Pokeman NFT Marketplace

This repository contains a full-stack decentralized application (Dapp) for a Pokémon-themed NFT marketplace. It features smart contracts built with Solidity and Foundry, and a React frontend using TypeScript and ethers.js to interact with the blockchain.

## 🌟 Features

### For Users:
- **Browse and Buy NFTs**: View a gallery of available Pokémon NFTs and purchase them using POKE tokens.
- **List NFTs**: List your owned NFTs on the marketplace for others to buy.
- **User Dashboard**:
    - **Stake POKE tokens**: Stake tokens to become eligible for minting new NFTs.
    - **Unstake tokens**: Withdraw staked tokens.
    - **Minting Cooldown**: See a live countdown for when your next NFT mint is available.
- **Receive POKE Token Airdrops**: The contract owner can airdrop POKE tokens to users.

### For the Contract Owner:
- **Owner-only Dashboard**: A special administrative panel visible only to the contract owner.
- **Airdrop Tokens**: Distribute POKE tokens to users.
- **Pre-Mint NFTs**: Mint NFTs to the marketplace contract's address to prepare them for sale.
- **Manage Minting**: Make specific pre-minted NFTs available for public minting.
- **List Pre-Minted NFTs**: List the contract-owned NFTs on the marketplace.

## 🛠️ Tech Stack

- **Blockchain**: Solidity, Foundry
- **Frontend**: React, TypeScript, ethers.js, CSS
- **Dependencies**: OpenZeppelin Contracts, forge-std

## 🚀 Getting Started

### Prerequisites
- [Node.js](https://nodejs.org/en/) (v18 or later)
- [Foundry](https://getfoundry.sh/)

### 1. Clone the Repository
```bash
git clone <repository-url>
cd pokeman
```

### 2. Install Dependencies
Install the Solidity contract dependencies and frontend packages.
```bash
forge install
cd frontend
yarn install
cd ..
```

### 3. Run a Local Blockchain Node
For development, you can run a local Anvil node. This command will start a node with a set of pre-funded accounts.
```bash
anvil
```
Keep this terminal window open.

### 4. Deploy Smart Contracts
In a new terminal, deploy the contracts to the local Anvil network. This script will also perform some initial setup, like airdropping tokens to a test user.
```bash
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast --private-key <your-anvil-private-key>
```
*Replace `<your-anvil-private-key>` with one of the private keys provided when you started the `anvil` node.*

### 5. Start the Frontend
Navigate to the `frontend` directory and start the React application.
```bash
cd frontend
yarn start
```
The application will be available at `http://localhost:3000`. Connect your MetaMask wallet (configured for the local Anvil network) to interact with the DApp.

## 📁 Project Structure

```
.
├── 📝 broadcast/      # Foundry broadcast outputs of transactions
├── 📝 cache/          # Foundry cache files
├── 📝 frontend/       # React frontend application
│   ├── src/
│   │   ├── abi/       # Contract ABIs
│   │   ├── App.tsx    # Main application component
│   │   ├── OwnerDashboard.tsx
│   │   └── UserDashboard.tsx
│   └── ...
├── 📝 lib/            # External dependencies (e.g., OpenZeppelin)
├── 📝 script/         # Solidity scripts for deployment and interaction
├── 📝 src/            # Solidity smart contracts
│   ├── PokeToken.sol        # ERC20 token
│   ├── PokemanNFT.sol       # ERC721 NFT
│   └── PokemanMarketplace.sol # Marketplace logic
└── 📝 test/           # Solidity tests for contracts
```

## 📜 Smart Contracts

- **`PokeToken.sol`**: An `ERC20` token used for all transactions within the marketplace.
- **`PokemanNFT.sol`**: An `ERC721` contract representing the Pokémon NFTs. Includes minting logic tied to staking.
- **`PokemanMarketplace.sol`**: The core contract that facilitates the buying and listing of NFTs. It handles the approval flow for both `ERC20` tokens and `ERC721` NFTs. It also includes the staking and minting cooldown logic.

## 🖥️ Frontend

The frontend is a single-page application built with React and TypeScript.
- **`ethers.js`** is used to communicate with the Ethereum blockchain.
- **`App.tsx`** is the main component that manages wallet connection, data fetching, and routing between user and owner views.
- **`NFTGallery.tsx`** displays the NFTs available for purchase.
- **`OwnerDashboard.tsx`** provides an admin interface for the contract owner.
- **`UserDashboard.tsx`** provides a user interface for staking and checking minting status.
- **Automatic UI Updates**: The UI automatically refreshes after any successful transaction, providing a seamless user experience.

---

Feel free to contribute to this project by submitting issues or pull requests.
