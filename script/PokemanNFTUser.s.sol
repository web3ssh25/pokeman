// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PokemanNFT.sol";
import "../src/PokeToken.sol";

contract PokemanNFTUser is Script {
    function run() external {
        // Read contract addresses and user private key from env
        address pokemanNFTAddress = vm.envAddress("POKEMANNFT_ADDRESS");
        address pokeTokenAddress = vm.envAddress("POKETOKEN_ADDRESS");
        uint256 user1PrivateKey = vm.envUint("USER1_PRIVATE_KEY");
        uint256 user2PrivateKey = vm.envUint("USER2_PRIVATE_KEY");
        address user1 = vm.addr(user1PrivateKey);
        address user2 = vm.addr(user1PrivateKey);

        PokemanNFT pokemanNFT = PokemanNFT(pokemanNFTAddress);
        PokeToken pokeToken = PokeToken(pokeTokenAddress);

        // Log user and contract info
        console.log("User address:", user1);
        console.log("PokemanNFT at:", pokemanNFTAddress);
        console.log("PokeToken at:", pokeTokenAddress);

        // --- 1. Stake POKEs ---
        uint256 stakeAmount = pokemanNFT.requiredStake();
        // Approve PokemanNFT to spend user's POKEs
        vm.startBroadcast(user1PrivateKey);
        pokeToken.approve(pokemanNFTAddress, stakeAmount);
        pokemanNFT.stake(stakeAmount);
        vm.stopBroadcast();
        console.log("Staked", stakeAmount, "POKEs");

        vm.startBroadcast(user2PrivateKey);
        pokeToken.approve(pokemanNFTAddress, stakeAmount);
        pokemanNFT.stake(stakeAmount);
        vm.stopBroadcast();
        console.log("Staked", stakeAmount, "POKEs");

        // --- 2. Mint a Pokeman NFT (assume ID 4 is available) ---
        // Wait for cooling period if needed (simulate with vm.warp in tests, not in live script)
        uint256 mintId = 4;
        vm.startBroadcast(user1PrivateKey);
        pokemanNFT.mint(mintId);
        vm.stopBroadcast();
        console.log("Minted Pokeman NFT with ID:", mintId);

        mintId = 5;
        vm.startBroadcast(user2PrivateKey);
        pokemanNFT.mint(mintId);
        vm.stopBroadcast();
        console.log("Minted Pokeman NFT with ID:", mintId);

        // --- 3. Unstake POKEs (after cooling period) ---
        // (In a real script, you must wait for the cooling period to pass)
        // vm.warp(block.timestamp + pokemanNFT.coolingPeriod()); // Only works in tests/sim
        // For live, you must wait in real time

        // Uncomment to unstake after cooling period:
        // vm.startBroadcast(user1PrivateKey);
        // pokemanNFT.unstake();
        // vm.stopBroadcast();
        // console.log("Unstaked POKEs");
    }
}