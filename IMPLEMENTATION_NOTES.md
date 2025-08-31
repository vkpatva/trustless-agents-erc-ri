# ERC-8004 Trustless Agents Reference Implementation

## Overview

This repository contains the official reference implementation for **[ERC-8004 Trustless Agents v0.3](https://eips.ethereum.org/EIPS/eip-8004)**, providing a complete, production-ready implementation of all three core registry contracts defined in the specification.

## Architecture

### Core Contracts

1. **`IdentityRegistry.sol`** - Central identity management
   - Unique agent ID assignment (sequential, starting from 1)
   - Domain and address mapping with duplicate prevention
   - Case-insensitive domain normalization for security
   - Update functionality with proper authorization

2. **`ReputationRegistry.sol`** - Lightweight feedback mechanism
   - Pre-authorization pattern for client feedback
   - Unique feedback authorization ID generation
   - Event-driven architecture for off-chain aggregation
   - Cross-agent relationship tracking

3. **`ValidationRegistry.sol`** - Independent work validation
   - Time-bounded validation requests (1000 seconds expiration)
   - Score-based responses (0-100 scale)
   - Prevention of double responses and self-validation
   - Automatic cleanup of expired requests and stale data

### Design Principles

- **Gas Efficiency**: Minimal on-chain storage with off-chain data pointers
- **Event-Driven**: Comprehensive event emission for off-chain indexing
- **Modular**: Each registry operates independently but references others as needed
- **Upgradeable**: Contracts reference each other via interfaces for future flexibility

## Key Features

### Identity Management
- Sequential agent ID assignment prevents confusion
- Dual mapping (domain ↔ agent ID, address ↔ agent ID) for efficient resolution
- Case-insensitive domain normalization prevents impersonation attacks
- Ownership verification prevents unauthorized registrations
- Comprehensive validation with clear error messages

### Reputation System
- Server-initiated feedback authorization ensures consent
- Unique authorization IDs prevent replay attacks
- Support for multiple client-server relationships
- Lightweight on-chain footprint

### Validation Framework
- Flexible validator assignment per request
- Time-bounded requests prevent stale validations
- Score-based responses support nuanced evaluation
- Automatic expiration and cleanup

## Gas Optimization

Current gas usage (first-time operations include storage setup costs):

- **Agent Registration**: ~142k gas
- **Feedback Authorization**: ~76k gas  
- **Validation Request**: ~115k gas
- **Validation Response**: ~78k gas

## Security Considerations

### Access Control
- Only agent owners can register and update their information
- Only designated validators can respond to validation requests
- Only server agents can authorize feedback
- Ownership verification prevents impersonation attacks

### Attack Prevention
- Case-insensitive domain normalization prevents bypass attacks
- Self-validation prevention maintains validation integrity
- Duplicate prevention for domains and addresses
- Time-bounded validation requests prevent resource exhaustion
- Event griefing prevention reduces spam attacks

### Data Integrity
- Immutable agent IDs ensure consistent references
- Event-driven architecture maintains audit trail
- Input validation prevents invalid state transitions
- Automatic cleanup of expired data prevents storage bloat

## Testing

The implementation includes 83 comprehensive tests covering:

- **Unit Tests**: Individual contract functionality
- **Integration Tests**: Cross-contract interactions
- **Edge Cases**: Boundary conditions and error states
- **Gas Optimization**: Performance validation
- **Real-World Scenarios**: End-to-end workflows

All tests pass with 100% success rate.

## Deployment

The reference implementation is designed for deployment on:

- **Ethereum Mainnet**: Full production environment
- **Sepolia Testnet**: Testing and development
- **Base**: L2 deployment for lower costs
- **Base Sepolia**: L2 testing environment

### Deployment Script

```bash
# Deploy to Sepolia testnet
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify

# Deploy to Base Sepolia
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
```

## Compliance with ERC-8004 v0.3

This implementation fully complies with ERC-8004 Trustless Agents v0.3 specification:

✅ **Identity Registry**: All required functions and events implemented  
✅ **Reputation Registry**: Pre-authorization pattern with event emission  
✅ **Validation Registry**: Time-bounded requests with score responses  
✅ **Error Handling**: Comprehensive custom errors as specified  
✅ **Gas Efficiency**: Optimized for minimal on-chain operations  

## Future Considerations

### ERC-721/6551 Integration
The current implementation uses a lightweight registry approach. Future versions may explore:

- ERC-721 tokens for agent identity (composability)
- ERC-6551 token-bound accounts (extensibility)
- Hybrid approaches balancing standards compliance with gas efficiency

### Protocol Evolution
As the ERC specification evolves (v0.4+), this implementation will be updated to maintain compatibility while preserving existing deployments through versioning.

## Development Workflow

1. **Clone & Setup**: `git clone` and `forge install`
2. **Environment**: Copy `.env.example` to `.env` and configure
3. **Build**: `forge build`
4. **Test**: `forge test`
5. **Deploy**: Use deployment scripts for target network

## Community

This reference implementation is maintained by the ERC-8004 working group and welcomes community contributions. All major changes should align with the evolving specification to maintain reference status.

---

**Note**: This implementation tracks ERC-8004 v0.3. Check the specification for the latest version and any required updates. 
