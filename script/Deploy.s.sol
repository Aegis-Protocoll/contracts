// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AegisRiskScore} from "../src/AegisRiskScore.sol";
import {MockDeFiProtocol} from "../src/MockDeFiProtocol.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey   = vm.envUint("PRIVATE_KEY");
        address backendWallet = vm.envAddress("BACKEND_WALLET");

        vm.startBroadcast(deployerKey);

        AegisRiskScore aegis = new AegisRiskScore();
        console.log("AegisRiskScore deployed at:", address(aegis));

        MockDeFiProtocol defi = new MockDeFiProtocol(address(aegis));
        console.log("MockDeFiProtocol deployed at:", address(defi));

        aegis.authorizeBackend(backendWallet);
        console.log("Backend authorized:", backendWallet);

        vm.stopBroadcast();

        console.log("\n=== Copy these into README.md ===");
        console.log("AegisRiskScore:", address(aegis));
        console.log("MockDeFiProtocol:", address(defi));
        console.log("Explorer: https://testnet-explorer.hsk.xyz/address/...");
    }
}
