// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IIdentityRegistry.sol";
import "./interfaces/IDIDValidator.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

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
contract IdentityRegistry is IIdentityRegistry, EIP712 {
    // ============ Constants ============
    string public constant VERSION = "1.3.0";
    string private constant SIGNING_DOMAIN = "IdentityRegistry";
    string private constant SIGNATURE_VERSION = "1";

    // ============ State Variables ============
    uint256 private _agentIdCounter;
    IDIDValidator public immutable didValidator;
    mapping(uint256 => AgentInfo) private _agents;
    mapping(address => uint256) private _addressToAgentId;
    mapping(string => uint256) private _didToAgentId;
    mapping(uint256 => string) private _agentIdToDeveloperDID;

    // ============ Struct ============
    struct AgentRegistrationParams {
        string developerDID;
        string agentDID;
        address agentAddress;
        string description;
        uint256 expiry;
        bytes agentSignature;
    }

    // ============ Constructor ============
    /**
     * @param validator Address of the deployed DIDValidator contract
     */
    constructor(address validator) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        require(validator != address(0), "Invalid DIDValidator address");
        didValidator = IDIDValidator(validator);
        _agentIdCounter = 1; // Start agent IDs from 1
    }

    // ============ EIP-712 ============
    bytes32 private constant AGENT_TYPEHASH =
        keccak256(
            "AgentRegistration(string developerDID,string agentDID,address agentAddress,string description,uint256 nonce,uint256 expiry)"
        );

    mapping(address => uint256) public nonces;

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

        emit AgentRegistered(agentId, agentAddress, agentDID);
    }

    /**
     * @notice Register a new agent by developer
     * @param developerDID DID of the developer performing registration
     * @param agentDID DID of the agent
     * @param agentAddress Ethereum address of the agent
     * @param description Free-form description
     * @param expiry Expiry timestamp of the signature
     * @param agentSignature EIP-712 signature by agent
     */
    function newAgentByDeveloperDID(
        string calldata developerDID,
        string calldata agentDID,
        address agentAddress,
        string calldata description,
        uint256 expiry,
        bytes calldata agentSignature
    ) external returns (uint256 agentId) {
        // Step 1: Validate Developer and Agent
        _validateDeveloperAndAgent(developerDID, agentDID, agentAddress);

        // Step 2: Verify signature
        _verifyAgentSignature(
            agentDID,
            developerDID,
            agentAddress,
            description,
            expiry,
            agentSignature
        );

        // Step 3: Check uniqueness
        _checkUniqueness(agentDID, agentAddress);

        // Step 4: Perform registration
        agentId = _performRegistration(
            developerDID,
            agentDID,
            agentAddress,
            description
        );
    }

    /**
     * @notice Register a new agent along with a developer DID (agent-initiated).
     * @dev Developer must later confirm the link in a 2-phase handshake.
     * @param agentDID DID of the agent
     * @param agentAddress Ethereum address of the agent
     * @param developerDID DID of the developer (claimed by the agent)
     * @param description Free-form description
     * @return agentId The unique ID assigned to the agent
     *
     * Requirements:
     * - Caller must be the same as `agentAddress`.
     * - `agentDID` must validate against `agentAddress`.
     * - Neither `agentDID` nor `agentAddress` may already be registered.
     */
    function newAgentWithDeveloperDID(
        string calldata agentDID,
        address agentAddress,
        string calldata developerDID,
        string calldata description
    ) external returns (uint256 agentId) {
        if (msg.sender != agentAddress) revert UnauthorizedRegistration();

        // Validate DID binding
        if (!didValidator.validateDID(agentDID, agentAddress)) {
            revert DIDAddressMismatch();
        }
        if (_didToAgentId[agentDID] != 0) revert DIDAlreadyRegistered();
        if (_addressToAgentId[agentAddress] != 0)
            revert AddressAlreadyRegistered();

        // Assign new ID
        agentId = _agentIdCounter++;

        // Store agent info
        _agents[agentId] = AgentInfo({
            agentId: agentId,
            agentDID: agentDID,
            agentAddress: agentAddress,
            description: description
        });

        // Map DID and address
        _didToAgentId[agentDID] = agentId;
        _addressToAgentId[agentAddress] = agentId;

        // Todo : later add developer confirmation system
        _agentIdToDeveloperDID[agentId] = developerDID;

        emit AgentRegistered(agentId, agentAddress, agentDID);
        emit AgentDeveloper(agentId, developerDID);
    }

    // ============ INTERNAL HELPER FUNCTIONS ============

    /**
     * @notice Validate developer and agent DIDs
     */
    function _validateDeveloperAndAgent(
        string calldata developerDID,
        string calldata agentDID,
        address agentAddress
    ) internal view {
        if (!didValidator.validateDID(developerDID, msg.sender)) {
            revert InvalidDeveloperDID();
        }
        if (!didValidator.validateDID(agentDID, agentAddress)) {
            revert DIDAddressMismatch();
        }
    }

    /**
     * @notice Verify agent signature using EIP-712
     */
    function _verifyAgentSignature(
        string calldata agentDID,
        string calldata developerDID,
        address agentAddress,
        string calldata description,
        uint256 expiry,
        bytes calldata agentSignature
    ) internal {
        // Check expiry first (cheaper check)
        if (block.timestamp > expiry) revert SignatureExpired();

        // Get and increment nonce
        uint256 nonce = nonces[agentAddress]++;

        // Build struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                AGENT_TYPEHASH,
                keccak256(bytes(developerDID)),
                keccak256(bytes(agentDID)),
                agentAddress,
                keccak256(bytes(description)),
                nonce,
                expiry
            )
        );

        // Final digest per EIP-712
        bytes32 digest = _hashTypedDataV4(structHash);

        // Recover and verify signer
        address recovered = ECDSA.recover(digest, agentSignature);
        if (recovered != agentAddress) revert InvalidAgentSignature();
    }

    /**
     * @notice Check if agent DID and address are unique
     */
    function _checkUniqueness(
        string calldata agentDID,
        address agentAddress
    ) internal view {
        if (_addressToAgentId[agentAddress] != 0) {
            revert AddressAlreadyRegistered();
        }
        if (_didToAgentId[agentDID] != 0) {
            revert DIDAlreadyRegistered();
        }
    }

    /**
     * @notice Perform the actual registration
     */
    function _performRegistration(
        string calldata developerDID,
        string calldata agentDID,
        address agentAddress,
        string calldata description
    ) internal returns (uint256 agentId) {
        // Generate new agent ID
        agentId = _agentIdCounter++;

        // Store agent info
        _agents[agentId] = AgentInfo({
            agentId: agentId,
            agentDID: agentDID,
            agentAddress: agentAddress,
            description: description
        });

        // Update mappings
        _didToAgentId[agentDID] = agentId;
        _addressToAgentId[agentAddress] = agentId;
        _agentIdToDeveloperDID[agentId] = developerDID;

        // Emit events
        emit AgentRegistered(agentId, agentAddress, agentDID);
        emit AgentDeveloper(agentId, developerDID);
    }

    // ============ New Functions ============

    /**
     * @notice Link a developer DID to an already registered agent.
     * @dev Only callable by the agent itself.
     * @param agentId The agent's unique identifier
     * @param developerDID The developer DID to associate
     */
    function addDeveloperDID(
        uint256 agentId,
        address developerAddress,
        string calldata developerDID
    ) external {
        AgentInfo storage agent = _agents[agentId];
        if (agent.agentId == 0) revert AgentNotFound();
        if (msg.sender != agent.agentAddress) revert UnauthorizedUpdate();
        // todo : in ideal world we would require developer's signature here too.
        // Validate developer DID matches caller (developer's Ethereum address)
        if (!didValidator.validateDID(developerDID, developerAddress)) {
            revert InvalidDeveloperDID();
        }

        _agentIdToDeveloperDID[agentId] = developerDID;
        emit AgentDeveloper(agentId, developerDID);
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
            agent.agentDID,
            agent.agentAddress,
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

    /**
     * @notice Resolve developer DID from an agent ID.
     * @param agentId The agent's unique identifier
     * @return developerDID The associated developer DID string
     */
    function resolveDeveloperDID(
        uint256 agentId
    ) external view returns (string memory developerDID) {
        if (_agents[agentId].agentId == 0) revert AgentNotFound();
        developerDID = _agentIdToDeveloperDID[agentId];
        if (bytes(developerDID).length == 0) revert DeveloperDIDAbsent();
    }
}
