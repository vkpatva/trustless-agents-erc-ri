# ERC-XXXX Trustless Agents: Reference Implementation

This repository contains the official reference implementation for **ERC-XXXX Trustless Agents**, a proposed standard for creating a trust layer for the open agent economy.

The goal of this implementation is to provide a concrete, working example of the smart contracts and interfaces defined in the specification. This serves to validate the design, facilitate discussion, and provide a foundational starting point for the community.

**This is a collaborative, open-source effort. Contributions are welcome.**

## Current Status

This implementation currently tracks **v0.3 of the ERC Specification**.

The ERC is a living document, and this repository will be updated in lockstep with the specification's evolution. As new versions like `v0.4` are discussed and released, this implementation will be updated accordingly. Please refer to the commit history and release tags to track changes between versions.

## Core Components

This repository contains the Solidity implementation for the three core on-chain registries defined in the ERC:

1. **`IdentityRegistry.sol`**: An on-chain "passport office" for agents
2. **`ReputationRegistry.sol`**: A lightweight, on-chain mechanism for recording attestations  
3. **`ValidationRegistry.sol`**: A generic interface for requesting and recording the results of independent work validation

## Architectural Discussion: Agent Identity (ERC-721/6551)

Based on recent discussions within the working group, this implementation explores the use of **ERC-721** for the agent's sovereign identity (the "passport") and **ERC-6551** for the agent's actor address (the "smart contract wallet").

This approach aims to achieve the best of both worlds:
- **Composability:** Agents become standard NFTs that can be used in the broader DeFi ecosystem
- **Extensibility:** Agents can have custom on-chain logic via their token-bound account

This implementation serves as a concrete proposal to the working group on how this can be achieved.

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Installation & Testing

```bash
# Clone the repository
git clone https://github.com/ChaosChain/trustless-agents-erc-ri.git
cd trustless-agents-erc-ri

# Install dependencies
forge install

# Run tests
forge test

# Run tests with gas reporting
forge test --gas-report
```

## Contract Architecture

### IdentityRegistry

The `IdentityRegistry` contract serves as the central registry for all agent identities. It implements:

- **Registration**: Agents register with a domain and address
- **Updates**: Agents can update their domain or address
- **Resolution**: Public functions to resolve agents by ID, domain, or address
- **Spam Protection**: 0.005 ETH burn fee for registration

### ReputationRegistry  

The `ReputationRegistry` enables lightweight feedback mechanisms:

- **Pre-authorization**: Server agents authorize clients to provide feedback
- **Event Emission**: All feedback is recorded via events for off-chain aggregation
- **Gas Efficiency**: Minimal on-chain storage, with detailed data stored off-chain

### ValidationRegistry

The `ValidationRegistry` provides hooks for independent validation:

- **Request/Response Pattern**: Validators can be requested and respond with scores
- **Flexible Validation**: Supports both crypto-economic and cryptographic verification
- **Time-bounded**: Requests expire after a configurable period

## Gas Optimization

This implementation prioritizes gas efficiency while maintaining security:

- Minimal on-chain storage with off-chain data pointers
- Event-driven architecture for data aggregation
- Optimized struct packing
- Efficient access patterns

## Testing

The test suite covers:

- All contract functionality
- Gas usage optimization  
- Edge cases and error conditions
- Integration scenarios

Run the full test suite:
```bash
forge test -vvv
```

## Contributing

This is a community-led effort. Contributions are highly encouraged!

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Community

Join the discussion in our [Telegram group](https://t.me/your-group-link) where the ERC working group collaborates.
