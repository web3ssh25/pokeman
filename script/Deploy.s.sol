//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PokeToken.sol";
import "../src/PokemanNFT.sol";
import "../src/PokemanMarketplace.sol";

contract Deploy is Script {
     
      function run() external returns (
        PokeToken pokeToken,
        PokemanNFT pokemanNFT,
        PokemanMarketplace marketplace
    ) {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address sender = vm.addr(privateKey);
        console.log("Using address:", sender);
        vm.startBroadcast(privateKey);

        // 1. Deploy PokeToken
        pokeToken = new PokeToken();
        console.log("PokeToken deployed at:", address(pokeToken));

        // 2. Deploy PokemanNFT, passing the PokeToken address to its constructor
        pokemanNFT = new PokemanNFT(address(pokeToken));
        console.log("PokemanNFT deployed at:", address(pokemanNFT));

        // 3. Deploy PokemanMarketplace, passing both contract addresses
        marketplace = new PokemanMarketplace(address(pokemanNFT), address(pokeToken));
        console.log("PokemanMarketplace deployed at:", address(marketplace));

         vm.stopBroadcast();
    }
}