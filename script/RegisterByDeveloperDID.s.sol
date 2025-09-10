// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/IdentityRegistry.sol";

contract RegisterAgentByDeveloper is Script {
    // Must match contract
    bytes32 private constant AGENT_TYPEHASH =
        keccak256(
            "AgentRegistration(string developerDID,string agentDID,address agentAddress,string description,uint256 nonce,uint256 expiry)"
        );

    // EIP-712 Domain typehash
    bytes32 private constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    function run() external {
        // === Keys ===
        uint256 developerKey = vm.envUint("DEVELOPER_KEY");
        address developer = vm.addr(developerKey);

        uint256 agentKey = vm.envUint("AGENT_KEY");
        address agent = vm.addr(agentKey);

        // === Inputs ===
        address identityRegistryAddress = vm.envAddress("IDENTITY_REGISTRY");
        string memory developerDid = vm.envString("DEVELOPER_DID");
        string memory agentDid = vm.envString("AGENT_DID");
        string memory description = vm.envString("AGENT_DESCRIPTION");
        uint256 expiry = block.timestamp + 1 days;

        IdentityRegistry identityRegistry = IdentityRegistry(
            identityRegistryAddress
        );

        // === Nonce ===
        uint256 nonce = identityRegistry.nonces(agent);

        // === Struct hash (must match contract) ===
        bytes32 structHash = keccak256(
            abi.encode(
                AGENT_TYPEHASH,
                keccak256(bytes(developerDid)), // 👈 now included
                keccak256(bytes(agentDid)),
                agent,
                keccak256(bytes(description)),
                nonce,
                expiry
            )
        );

        // === Domain separator ===
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes("IdentityRegistry")), // SIGNING_DOMAIN
                keccak256(bytes("1")), // SIGNATURE_VERSION
                block.chainid,
                identityRegistryAddress
            )
        );

        // === Final digest ===
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        // === Sign with agent key ===
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(agentKey, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // === Broadcast as developer ===
        vm.startBroadcast(developerKey);

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
