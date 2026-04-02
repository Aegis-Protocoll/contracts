// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAegisRiskScore {
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

    function updateRiskScore(
        address wallet,
        uint8 score,
        bytes32[4] calldata flags,
        bytes32 reasoning,
        uint8 hopDistance
    ) external;
    function getRiskProfile(
        address wallet
    ) external view returns (RiskProfile memory);
    function getRiskLevel(address wallet) external view returns (RiskLevel);
    function isCompliant(address wallet) external view returns (bool);
    function getScore(address wallet) external view returns (uint8);
    function isStale(
        address wallet,
        uint256 maxAge
    ) external view returns (bool);
}
