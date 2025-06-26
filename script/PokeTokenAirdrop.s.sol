// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PokeToken.sol";
import "./Deploy.s.sol";

contract PokeTokenAirdrop is Script {

    function run() external {
        address pokeTokenAddress = vm.envAddress("POKETOKEN_ADDRESS");
        console.log(pokeTokenAddress);
        // If the address is zero, the deployment probably hasn't run yet.
        require(pokeTokenAddress != address(0), "PokeToken address not found. Did you run the deploy script?");

        // Create an instance of the PokeToken contract at the deployed address
        PokeToken pokeToken = PokeToken(pokeTokenAddress);
        console.log("Interacting with PokeToken at:", pokeTokenAddress);
        console.log("Contract owner is:", pokeToken.owner());

        // --- Define Airdrop Recipients and Amounts ---
        address[] memory recipients = new address[](2);
        recipients[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Anvil Account #1
        recipients[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Anvil Account #2

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether; 
        amounts[1] = 200 ether; 

        console.log("Airdropping to %d users...", recipients.length);
        console.log("Balance of %s before: %d", recipients[0], pokeToken.balanceOf(recipients[0]));
        console.log("Balance of %s before: %d", recipients[1], pokeToken.balanceOf(recipients[1]));

        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // --- Start Broadcasting the Transaction ---
        vm.startBroadcast(privateKey);

        pokeToken.batchAirdrop(recipients, amounts);

        vm.stopBroadcast();
        // --- End Broadcasting ---

        console.log("Airdrop complete!");
        console.log("Balance of %s after: %d", recipients[0], pokeToken.balanceOf(recipients[0]));
        console.log("Balance of %s after: %d", recipients[1], pokeToken.balanceOf(recipients[1]));
    }
}