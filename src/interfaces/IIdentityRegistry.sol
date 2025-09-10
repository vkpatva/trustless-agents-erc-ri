// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IIdentityRegistry
/// @notice Interface for a decentralized identity registry for ERC-8004 Trustless Agents
/// @dev Provides functions to register, update, and resolve agent identities by ID, address, or DID
interface IIdentityRegistry {
    // ============ Events ============

    /// @notice Emitted when a new agent is registered
    /// @param agentId Unique identifier of the agent
    /// @param agentAddress Ethereum address associated with the agent
    event AgentRegistered(
        uint256 indexed agentId,
        address indexed agentAddress,
        string indexed agentDID
    );

    /// @notice Emitted when an agent’s information is updated
    /// @param agentId Unique identifier of the agent
    /// @param agentAddress Updated Ethereum address of the agent
    /// @param agentDID Updated DID string of the agent
    /// @param description Updated human-readable description of the agent
    event AgentUpdated(
        uint256 indexed agentId,
        string indexed agentDID,
        address agentAddress,
        string description
    );

    // todo : complete documentation
    event AgentDeveloper(uint256 indexed agentId, string developerDID);
    // ============ Structs ============

    /// @notice Struct holding information about a registered agent
    struct AgentInfo {
        uint256 agentId; // Unique identifier for the agent
        string agentDID; // Optional DID string (can be empty if not set)
        address agentAddress; // Ethereum address of the agent
        string description; // Human-readable description of the agent
    }

    // ============ Errors ============

    /// @notice Thrown when an agent is not found
    error AgentNotFound();

    /// @notice Thrown when the caller is not authorized to update an agent
    error UnauthorizedUpdate();

    /// @notice Thrown when the caller is not authorized to register an agent
    error UnauthorizedRegistration();

    /// @notice Thrown when an invalid (zero) address is provided
    error InvalidAddress();

    /// @notice Thrown when input values are invalid (e.g., empty required fields)
    error InvalidInput();

    /// @notice Thrown when the provided address is already registered
    error AddressAlreadyRegistered();

    /// @notice Thrown when the provided DID is already registered
    error DIDAlreadyRegistered();

    /// @notice Thrown when a DID is expected but not registered
    error DIDNotRegistered();

    /// @notice Thrown when the provided DID does not match the stored address
    error DIDAddressMismatch();

    // @notice Thrown when the signature provided by Agent is not valid
    error InvalidAgentSignature();

    // @notice Thrown when the developer DID is not valid
    error InvalidDeveloperDID();

    // @notice Thrown when the signature is expired
    error SignatureExpired();

    // @notice Thrown when Developer DID is not found
    error DeveloperDIDAbsent();

    // ============ Write Functions ============

    /**
     * @notice Register a new agent in the registry
     * @dev Reverts if the address or DID is already registered
     * @param agentDID DID string associated with the agent (can be optional but must be unique if provided)
     * @param agentAddress Ethereum address to associate with the agent
     * @param description Human-readable description of the agent
     * @return agentId The unique identifier assigned to the newly registered agent
     */
    function newAgent(
        string calldata agentDID,
        address agentAddress,
        string calldata description
    ) external returns (uint256 agentId);

    /**
     * @notice Update an existing agent’s information
     * @dev Caller must be authorized to update the agent
     * @param agentId Unique identifier of the agent
     * @param newAgentAddress New Ethereum address (use zero address to leave unchanged)
     * @param newAgentDID New DID string (use empty string to clear DID)
     * @param newDescription New description (use empty string to leave unchanged)
     * @return success True if update was successful
     */
    function updateAgent(
        uint256 agentId,
        address newAgentAddress,
        string calldata newAgentDID,
        string calldata newDescription
    ) external returns (bool success);

    // ============ Read Functions ============

    /**
     * @notice Fetch details of an agent by ID
     * @param agentId Unique identifier of the agent
     * @return agentInfo Struct containing the agent’s full information
     */
    function getAgent(
        uint256 agentId
    ) external view returns (AgentInfo memory agentInfo);

    /**
     * @notice Resolve agent details by Ethereum address
     * @param agentAddress Ethereum address associated with the agent
     * @return agentInfo Struct containing the agent’s full information
     */
    function resolveByAddress(
        address agentAddress
    ) external view returns (AgentInfo memory agentInfo);

    /**
     * @notice Resolve agent details by DID
     * @param agentDID DID string associated with the agent
     * @return agentInfo Struct containing the agent’s full information
     */
    function resolveByDID(
        string calldata agentDID
    ) external view returns (AgentInfo memory agentInfo);

    /**
     * @notice Get the total number of registered agents
     * @return count Number of agents currently registered
     */
    function getAgentCount() external view returns (uint256 count);

    /**
     * @notice Check if an agent exists by ID
     * @param agentId Unique identifier of the agent
     * @return exists True if the agent exists, false otherwise
     */
    function agentExists(uint256 agentId) external view returns (bool exists);
}
