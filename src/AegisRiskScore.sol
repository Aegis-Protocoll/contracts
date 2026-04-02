// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AegisRiskScore
 * @notice Stores AI-generated risk scores for wallets on HashKey Chain.
 *         Scoring methodology (inspired by Range):
 *         L1: Attribution override — known clean = always score 1
 *         L2: Sanctions screening — sanctioned = always score 10
 *         L3: Graph proximity analysis — hop distance to malicious actors
 *         L4: AI behavioral enhancement — OpenAI pattern analysis
 * @dev Written by authorized Aegis backend, readable by any protocol.
 */
contract AegisRiskScore is Ownable {
    error UnauthorizedBackend();
    error InvalidScore();

    enum RiskLevel {
        UNKNOWN,
        VERY_LOW,
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    struct RiskProfile {
        uint8 score;
        RiskLevel level;
        bool isCompliant;
        uint8 hopDistance;
        uint64 updatedAt;
        bytes32 reasoning;
        bytes32[4] flags;
    }

    mapping(address => RiskProfile) private _profiles;
    mapping(address => bool) public authorizedBackends;
    mapping(address => bool) public knownCleanAddresses;

    event RiskScoreUpdated(
        address indexed wallet,
        uint8 score,
        RiskLevel level,
        bytes32[4] flags
    );
    event BackendAuthorized(address indexed backend);
    event CleanAddressAdded(address indexed addr);

    modifier onlyBackend() {
        if (!authorizedBackends[msg.sender]) revert UnauthorizedBackend();
        _;
    }

    constructor() Ownable(msg.sender) {}

    function updateRiskScore(
        address wallet,
        uint8 score,
        bytes32[4] calldata flags,
        bytes32 reasoning,
        uint8 hopDistance
    ) external onlyBackend {
        if (score < 1 || score > 10) revert InvalidScore();

        if (knownCleanAddresses[wallet]) score = 1;

        RiskLevel level;
        bool compliant;

        if (score == 1) {
            level = RiskLevel.VERY_LOW;
            compliant = true;
        } else if (score <= 3) {
            level = RiskLevel.LOW;
            compliant = true;
        } else if (score <= 6) {
            level = RiskLevel.MEDIUM;
            compliant = true;
        } else if (score <= 9) {
            level = RiskLevel.HIGH;
            compliant = false;
        } else {
            level = RiskLevel.CRITICAL;
            compliant = false;
        }

        _profiles[wallet] = RiskProfile({
            score: score,
            level: level,
            updatedAt: uint64(block.timestamp),
            flags: flags,
            reasoning: reasoning,
            isCompliant: compliant,
            hopDistance: hopDistance
        });

        emit RiskScoreUpdated(wallet, score, level, flags);
    }

    function getRiskProfile(
        address wallet
    ) external view returns (RiskProfile memory) {
        return _profiles[wallet];
    }

    function isCompliant(address wallet) external view returns (bool) {
        if (knownCleanAddresses[wallet]) return true;
        RiskProfile memory p = _profiles[wallet];
        if (p.updatedAt == 0) return true;
        return p.isCompliant;
    }

    function getScore(address wallet) external view returns (uint8) {
        if (knownCleanAddresses[wallet]) return 1;
        return _profiles[wallet].score;
    }

    function isStale(
        address wallet,
        uint256 maxAge
    ) external view returns (bool) {
        return (block.timestamp - _profiles[wallet].updatedAt) > maxAge;
    }

    function authorizeBackend(address backend) external onlyOwner {
        authorizedBackends[backend] = true;
        emit BackendAuthorized(backend);
    }

    function revokeBackend(address backend) external onlyOwner {
        authorizedBackends[backend] = false;
    }

    function addKnownClean(address addr) external onlyOwner {
        knownCleanAddresses[addr] = true;
        emit CleanAddressAdded(addr);
    }

    function removeKnownClean(address addr) external onlyOwner {
        knownCleanAddresses[addr] = false;
    }
}
