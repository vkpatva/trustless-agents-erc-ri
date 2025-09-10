// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/IdentityRegistry.sol";

contract RegisterAgentByDeveloper is Script {
    // Match the typehash used in your contract
    bytes32 private constant AGENT_CONSENT_TYPEHASH =
        keccak256(
            "AgentConsent(string agentDID,address agentAddress,string description,uint256 expiry)"
        );

    function run() external {
        // Developer (sends tx)
        uint256 developerKey = vm.envUint("DEVELOPER_KEY");
        address developer = vm.addr(developerKey);

        // Agent (signs)
        uint256 agentKey = vm.envUint("AGENT_KEY");
        address agent = vm.addr(agentKey);

        // Inputs
        address identityRegistryAddress = vm.envAddress("IDENTITY_REGISTRY");
        string memory developerDid = vm.envString("DEVELOPER_DID");
        string memory agentDid = vm.envString("AGENT_DID");
        string memory description = vm.envString("AGENT_DESCRIPTION");
        uint256 expiry = block.timestamp + 1 days;

        // Build struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                AGENT_CONSENT_TYPEHASH,
                keccak256(bytes(agentDid)),
                agent,
                keccak256(bytes(description)),
                expiry
            )
        );

        // Normally _hashTypedDataV4(domain, structHash), but we just sign structHash
        bytes32 digest = structHash;

        // Sign with agent key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(agentKey, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // Broadcast as developer
        vm.startBroadcast(developerKey);

        IdentityRegistry identityRegistry = IdentityRegistry(
            identityRegistryAddress
        );

        uint256 agentId = identityRegistry.newAgentByDeveloperDID(
            developerDid,
            agentDid,
            agent,
            description,
            expiry,
            sig
        );

        console.log("Agent registered successfully");
        console.log("Agent ID:", agentId);
        console.log("Agent DID:", agentDid);
        console.log("Developer DID:", developerDid);
        console.log("Agent Address:", agent);
        console.log("Expiry:", expiry);

        vm.stopBroadcast();
    }
}
