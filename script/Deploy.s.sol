// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/IdentityRegistry.sol";
import "../src/ReputationRegistry.sol";
import "../src/ValidationRegistry.sol";
import "../src/DIDValidator.sol";

/**
 * @title Deploy
 * @dev Deployment script for ERC-8004 Trustless Agents Reference Implementation
 * @notice Deploys DIDValidator first, then IdentityRegistry (using DIDValidator),
 *         followed by ReputationRegistry and ValidationRegistry.
 */
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log(
            "Deploying ERC-8004 Trustless Agents Reference Implementation..."
        );
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // 1. Deploy DIDValidator
        console.log("\n1. Deploying DIDValidator...");
        DIDValidator didValidator = new DIDValidator();
        console.log("DIDValidator deployed at:", address(didValidator));

        // 2. Deploy IdentityRegistry with DIDValidator dependency
        console.log("\n2. Deploying IdentityRegistry...");
        IdentityRegistry identityRegistry = new IdentityRegistry(
            address(didValidator)
        );
        console.log("IdentityRegistry deployed at:", address(identityRegistry));

        // // 3. Deploy ReputationRegistry (depends on IdentityRegistry)
        // console.log("\n3. Deploying ReputationRegistry...");
        // ReputationRegistry reputationRegistry = new ReputationRegistry(
        //     address(identityRegistry)
        // );
        // console.log(
        //     "ReputationRegistry deployed at:",
        //     address(reputationRegistry)
        // );

        // // 4. Deploy ValidationRegistry (depends on IdentityRegistry)
        // console.log("\n4. Deploying ValidationRegistry...");
        // ValidationRegistry validationRegistry = new ValidationRegistry(
        //     address(identityRegistry)
        // );
        // console.log(
        //     "ValidationRegistry deployed at:",
        //     address(validationRegistry)
        // );

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("DIDValidator:", address(didValidator));
        console.log("IdentityRegistry:", address(identityRegistry));
        // console.log("ReputationRegistry:", address(reputationRegistry));
        // console.log("ValidationRegistry:", address(validationRegistry));
    }
}
