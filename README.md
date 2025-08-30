# ERC-8004 Trustless Agents Reference Implementation


The **official reference implementation** for **[ERC-8004 Trustless Agents v0.3](https://eips.ethereum.org/EIPS/eip-8004)** - a trust layer that enables participants to discover, choose, and interact with agents across organizational boundaries without pre-existing trust.

## Overview

This repository provides a complete, production-ready implementation of all three core registry contracts defined in the ERC-8004 specification:

- **Identity Registry** - Central identity management
- **Reputation Registry** - Lightweight feedback authorization system  
- **Validation Registry** - Independent work validation with time bounds


## Live Example & Demo

To see these contracts in a live, end-to-end workflow, check out our complete working example. It demonstrates how to build a full application with AI agents that interact trustlessly on-chain using the ERC-8004 standard.

**Explore the ERC-8004 Example Repo:** **https://github.com/ChaosChain/erc-8004-example**

The example includes:
- **A full demonstration** of the agent registration, validation, and feedback lifecycle.
- **A self-contained environment** that's easy to run and explore.


## Architecture

### Core Contracts

| Contract | Purpose | Gas Cost | Key Features |
|----------|---------|----------|--------------|
| `IdentityRegistry` | Agent identity management | ~142k gas | Sequential IDs, domain/address uniqueness |
| `ReputationRegistry` | Feedback authorization | ~76k gas | Pre-authorization pattern, unique auth IDs |
| `ValidationRegistry` | Work validation | ~115k gas | Time-bounded requests, score responses |

### Design Principles

- **Gas Efficient** - Minimal on-chain storage with off-chain data pointers
- **Event-Driven** - Comprehensive event emission for off-chain indexing
- **Modular** - Each registry operates independently but references others as needed
- **Upgradeable** - Contracts reference each other via interfaces for future flexibility

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/) installed
- Node.js 16+ (optional, for additional tooling)

### Installation

```bash
git clone https://github.com/ChaosChain/trustless-agents-erc-ri.git
cd trustless-agents-erc-ri
forge install
```

### Build & Test

```bash
# Build contracts
forge build

# Run all tests (82 tests, 100% pass rate)
forge test

# Run tests with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/IdentityRegistry.t.sol
```

### Deploy

```bash
# Configure environment
cp .env.example .env
# Edit .env with your settings

# Deploy to Sepolia testnet
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify

# Deploy to Base Sepolia
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
```

##  Contract Specifications

### Identity Registry

**Purpose**: Central registry for all agent identities

```solidity
interface IIdentityRegistry {
    function newAgent(string calldata agentDomain, address agentAddress) 
        external payable returns (uint256 agentId);
    
    function updateAgent(uint256 agentId, string calldata newAgentDomain, address newAgentAddress) 
        external returns (bool success);
    
    function getAgent(uint256 agentId) 
        external view returns (AgentInfo memory);
    
    function resolveByDomain(string calldata agentDomain) 
        external view returns (AgentInfo memory);
    
    function resolveByAddress(address agentAddress) 
        external view returns (AgentInfo memory);
}
```

**Key Features**:
- Sequential agent ID assignment (starting from 1)

- Dual mapping: domain ↔ agent ID, address ↔ agent ID
- Update functionality with proper authorization

### Reputation Registry

**Purpose**: Lightweight entry point for task feedback between agents

```solidity
interface IReputationRegistry {
    function acceptFeedback(uint256 agentClientId, uint256 agentServerId) external;
    
    function isFeedbackAuthorized(uint256 agentClientId, uint256 agentServerId) 
        external view returns (bool isAuthorized, bytes32 feedbackAuthId);
}
```

**Key Features**:
- Pre-authorization pattern for client feedback
- Unique feedback authorization ID generation
- Event-driven architecture for off-chain aggregation
- Cross-agent relationship tracking

### Validation Registry

**Purpose**: Generic hooks for requesting and recording independent validation

```solidity
interface IValidationRegistry {
    function validationRequest(uint256 agentValidatorId, uint256 agentServerId, bytes32 dataHash) external;
    
    function validationResponse(bytes32 dataHash, uint8 response) external;
    
    function getValidationRequest(bytes32 dataHash) 
        external view returns (Request memory);
    
    function isValidationPending(bytes32 dataHash) 
        external view returns (bool exists, bool pending);
}
```

**Key Features**:
- Time-bounded validation requests (1000 blocks expiration)
- Score-based responses (0-100 scale)
- Prevention of double responses
- Automatic cleanup of expired requests

## Testing

Our comprehensive test suite includes **82 tests** with **100% pass rate**:

### Test Categories

| Category | Tests | Coverage |
|----------|-------|----------|
| **Unit Tests** | 74 | Individual contract functionality |
| **Integration Tests** | 8 | Cross-contract interactions |
| **Edge Cases** | ✅ | Boundary conditions and error states |
| **Gas Optimization** | ✅ | Performance validation |
| **Real-World Scenarios** | ✅ | End-to-end workflows |

### Running Specific Tests

```bash
# Identity Registry tests
forge test --match-path test/IdentityRegistry.t.sol -v

# Reputation Registry tests  
forge test --match-path test/ReputationRegistry.t.sol -v

# Validation Registry tests
forge test --match-path test/ValidationRegistry.t.sol -v

# Integration tests
forge test --match-path test/Integration.t.sol -v
```

## Gas Usage

Current gas usage (optimized for efficiency):

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Agent Registration | ~142k gas | First-time setup includes storage costs |
| Feedback Authorization | ~76k gas | Lightweight authorization |
| Validation Request | ~115k gas | Includes storage setup |
| Validation Response | ~78k gas | Score submission |

## Security Features

### Access Control
- **Ownership Verification**: Only agent owners can register their own addresses (prevents impersonation)
- **Authorized Updates**: Only agent owners can update their information
- **Validator Authorization**: Only designated validators can respond to validation requests  
- **Server Authorization**: Only server agents can authorize feedback

### Attack Prevention
- **Case-Sensitivity Protection**: Domain normalization prevents case-variance bypass attacks
- **Self-Validation Prevention**: Agents cannot validate their own work to maintain integrity
- **Duplicate Prevention**: Domains and addresses can only be registered once
- **Time-bounded Requests**: Validation requests prevent resource exhaustion with automatic expiration

### Data Integrity
- **Immutable Agent IDs**: Ensure consistent references across the system
- **Event-driven Architecture**: Maintains comprehensive audit trail
- **Input Validation**: Prevents invalid state transitions
- **Stale Data Cleanup**: Automatic cleanup of expired validation responses

### Modern Security Standards
- **Meta-transaction Compatible**: Uses `msg.sender` instead of deprecated `tx.origin`
- **Post-merge Compatibility**: Uses `block.prevrandao` instead of deprecated `block.difficulty`
- **Version Tracking**: All contracts include version constants for upgrade management
- **Security Audited**: All identified vulnerabilities have been fixed and tested

### Security Testing
- **Comprehensive Security Tests**: Includes tests for all security fixes
- **Attack Vector Coverage**: Tests for impersonation, case-sensitivity, and self-validation attacks
- **Edge Case Testing**: Covers boundary conditions and error scenarios

## Deployment Networks

The reference implementation supports deployment on:

- **Ethereum Mainnet** - Full production environment
- **Sepolia Testnet** - Testing and development
- **Base** - L2 deployment for lower costs
- **Base Sepolia** - L2 testing environment

## Documentation

- **[Implementation Notes](./IMPLEMENTATION_NOTES.md)** - Detailed technical documentation
- **[ERC Specification]()**

## Contributing

This reference implementation is maintained by the ERC-8004 working group. Contributions are welcome!

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add comprehensive tests
5. Ensure all tests pass: `forge test` (82 tests should pass)
6. Submit a pull request

### Code Standards

- Follow Solidity style guide
- Include NatSpec documentation
- Add tests for new functionality  
- Maintain gas efficiency
- Ensure backward compatibility

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- The ERC-8004 working group for specification development
- The [A2A Protocol](https://a2a-protocol.org/) team for the foundational work
- OpenZeppelin for security patterns and best practices
- The Ethereum community for feedback and support

## 🔗 Links

- **Repository**: [github.com/ChaosChain/trustless-agents-erc-ri](https://github.com/ChaosChain/trustless-agents-erc-ri)
- **ERC Specification**: [ERC-8004 Trustless Agents v0.3](https://eips.ethereum.org/EIPS/eip-8004)
- **A2A Protocol**: [a2a-protocol.org](https://a2a-protocol.org/)

---

**Built with ❤️ by ChaosChain for the open AI agentic economy**
