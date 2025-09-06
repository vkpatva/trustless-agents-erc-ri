// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IIdentityRegistry.sol";
import "./interfaces/IDIDValidator.sol";

/**
 * @title IdentityRegistry
 * @dev Central registry for ERC-8004 Trustless Agents with DID validation support.
 * @notice This contract manages agent registrations, ensuring uniqueness of Ethereum addresses and DIDs.
 *         DID validation is delegated to an external DIDValidator contract, making the registry modular
 *         and upgradeable without needing to redeploy the core registry logic.
 *
 * Features:
 * - One DID and one Ethereum address per agent (1:1 mapping).
 * - Prevents duplicate DID or address registrations.
 * - Ensures DIDs actually embed the claimed Ethereum address via DIDValidator.
 * - Supports updating agent DID, address, and description with validation.
 *
 * Version: 1.3.0
 * Author: Vkpatva - Zkred
 */
contract IdentityRegistry is IIdentityRegistry {
    // ============ Constants ============
    string public constant VERSION = "1.3.0";

    // ============ State Variables ============
    uint256 private _agentIdCounter;
    IDIDValidator public immutable didValidator;

    mapping(uint256 => AgentInfo) private _agents;
    mapping(address => uint256) private _addressToAgentId;
    mapping(string => uint256) private _didToAgentId;

    // ============ Constructor ============
    /**
     * @param validator Address of the deployed DIDValidator contract
     */
    constructor(address validator) {
        require(validator != address(0), "Invalid DIDValidator address");
        didValidator = IDIDValidator(validator);
        _agentIdCounter = 1; // Start agent IDs from 1
    }

    // ============ Write Functions ============

    /**
     * @notice Register a new agent with a DID and Ethereum address.
     * @dev DID must validate against the claimed address if provided.
     * @param agentDID Decentralized Identifier (optional: can be empty string)
     * @param agentAddress Ethereum address of the agent
     * @param description Free-form description about the agent
     * @return agentId The unique ID assigned to the agent
     *
     * Requirements:
     * - Caller must be the same as `agentAddress`.
     * - If `agentDID` is provided, it must:
     *    - Embed `agentAddress` (verified via DIDValidator).
     *    - Not already be registered.
     * - `agentAddress` must not already be registered.
     */
    function newAgent(
        string calldata agentDID,
        address agentAddress,
        string calldata description
    ) external override returns (uint256 agentId) {
        if (msg.sender != agentAddress) revert UnauthorizedRegistration();

        if (bytes(agentDID).length > 0) {
            if (_didToAgentId[agentDID] != 0) revert DIDAlreadyRegistered();
            // Validate DID structure and address binding
            if (!didValidator.validateDID(agentDID, agentAddress)) {
                revert DIDAddressMismatch();
            }
        }

        if (_addressToAgentId[agentAddress] != 0)
            revert AddressAlreadyRegistered();

        agentId = _agentIdCounter++;

        _agents[agentId] = AgentInfo(
            agentId,
            agentDID,
            agentAddress,
            description
        );

        if (bytes(agentDID).length > 0) {
            _didToAgentId[agentDID] = agentId;
        }
        _addressToAgentId[agentAddress] = agentId;

        emit AgentRegistered(agentId, agentAddress);
    }

    /**
     * @notice Update an agent's DID, Ethereum address, or description.
     * @param agentId The agent's unique identifier
     * @param newAgentAddress New Ethereum address (zero = no change)
     * @param newAgentDID New DID (empty string = clear DID)
     * @param newDescription New description (empty string = no change)
     * @return success True if update completed
     *
     * Requirements:
     * - Caller must be the currently registered `agent.agentAddress`.
     * - If new DID is provided, it must:
     *    - Embed the address being used (old or new).
     *    - Not already be registered.
     * - New address (if provided) must not already be registered.
     */
    function updateAgent(
        uint256 agentId,
        address newAgentAddress,
        string calldata newAgentDID,
        string calldata newDescription
    ) external override returns (bool success) {
        AgentInfo storage agent = _agents[agentId];
        if (agent.agentId == 0) revert AgentNotFound();
        if (msg.sender != agent.agentAddress) revert UnauthorizedUpdate();

        bool addressChanged = newAgentAddress != address(0);
        bool descriptionChanged = bytes(newDescription).length > 0;

        // Address to validate DID against
        address addressForDIDValidation = addressChanged
            ? newAgentAddress
            : agent.agentAddress;

        // --- Address update ---
        if (addressChanged) {
            if (_addressToAgentId[newAgentAddress] != 0)
                revert AddressAlreadyRegistered();

            delete _addressToAgentId[agent.agentAddress];
            agent.agentAddress = newAgentAddress;
            _addressToAgentId[newAgentAddress] = agentId;
        }

        // --- DID update ---
        {
            if (bytes(agent.agentDID).length > 0) {
                delete _didToAgentId[agent.agentDID];
            }

            if (bytes(newAgentDID).length > 0) {
                if (
                    !didValidator.validateDID(
                        newAgentDID,
                        addressForDIDValidation
                    )
                ) {
                    revert DIDAddressMismatch();
                }
                if (_didToAgentId[newAgentDID] != 0)
                    revert DIDAlreadyRegistered();
                agent.agentDID = newAgentDID;
                _didToAgentId[newAgentDID] = agentId;
            } else {
                agent.agentDID = "";
            }
        }

        // --- Description update ---
        if (descriptionChanged) {
            agent.description = newDescription;
        }

        emit AgentUpdated(
            agentId,
            agent.agentAddress,
            agent.agentDID,
            agent.description
        );

        return true;
    }

    /**
     * @notice Update agent description only.
     * @param agentId The agent's unique identifier
     * @param newDescription The new description string
     * @return success True if update completed
     *
     * Requirements:
     * - Caller must be the registered `agent.agentAddress`.
     */
    function updateDescription(
        uint256 agentId,
        string calldata newDescription
    ) external returns (bool success) {
        AgentInfo storage agent = _agents[agentId];
        if (agent.agentId == 0) revert AgentNotFound();
        if (msg.sender != agent.agentAddress) revert UnauthorizedUpdate();

        agent.description = newDescription;
        return true;
    }

    // ============ Read Functions ============

    function getAgent(
        uint256 agentId
    ) external view override returns (AgentInfo memory agentInfo) {
        agentInfo = _agents[agentId];
        if (agentInfo.agentId == 0) revert AgentNotFound();
    }

    function resolveByAddress(
        address agentAddress
    ) external view override returns (AgentInfo memory agentInfo) {
        uint256 agentId = _addressToAgentId[agentAddress];
        if (agentId == 0) revert AgentNotFound();
        agentInfo = _agents[agentId];
    }

    function resolveByDID(
        string calldata agentDID
    ) external view override returns (AgentInfo memory agentInfo) {
        uint256 agentId = _didToAgentId[agentDID];
        if (agentId == 0) revert DIDNotRegistered();
        agentInfo = _agents[agentId];
    }

    function getAgentCount() external view override returns (uint256 count) {
        return _agentIdCounter - 1;
    }

    function agentExists(
        uint256 agentId
    ) external view override returns (bool exists) {
        return _agents[agentId].agentId != 0;
    }
}
