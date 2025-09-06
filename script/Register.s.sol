// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/IdentityRegistry.sol";

/// @title RegisterAgent
/// @notice Script to register a new agent in the IdentityRegistry
contract RegisterAgent is Script {
    function run() external {
        // Registrar private key from env
        uint256 registrarKey = vm.envUint("REGISTRAR_KEY");
        address registrar = vm.addr(registrarKey);

        // Contract + agent metadata from env
        address identityRegistryAddress = vm.envAddress("IDENTITY_REGISTRY");
        string memory agentDid = vm.envString("AGENT_DID");
        string memory agentDescription = vm.envString("AGENT_DESCRIPTION");

        vm.startBroadcast(registrarKey);

        console.log("Registering agent...");
        console.log("Registrar:", registrar);
        console.log("IdentityRegistry:", identityRegistryAddress);

        IdentityRegistry identityRegistry = IdentityRegistry(
            identityRegistryAddress
        );

        // Call your registry function
        identityRegistry.newAgent(agentDid, registrar, agentDescription);

        console.log("Agent registered successfully");
        console.log("Agent Address:", registrar);
        console.log("Agent DID:", agentDid);

        vm.stopBroadcast();
    }
}
