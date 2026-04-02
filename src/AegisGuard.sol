// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AegisRiskScore} from "./AegisRiskScore.sol";

/**
 * @title AegisGuard
 * @notice Abstract base contract. DeFi protocols inherit this to get
 *         AI-powered compliance enforcement automatically.
 *
 * @dev Usage (2 lines only):
 *
 *   import "./AegisGuard.sol";
 *
 *   contract MyDEX is AegisGuard {
 *       constructor() AegisGuard(AEGIS_ADDRESS_ON_HSK) {}
 *       function swap() external onlyCompliant { ... }
 *   }
 */
abstract contract AegisGuard {
    error WalletNonCompliant();
    error WalletBlocked();

    AegisRiskScore public immutable AEGIS;

    // Score >= 7 = non-compliant (HIGH risk)
    // Mirrors Range's DeFi recommendation
    uint8 public constant COMPLIANCE_THRESHOLD = 7;

    constructor(address _aegisRiskScore) {
        AEGIS = AegisRiskScore(_aegisRiskScore);
    }

    /// @notice Blocks wallets with score >= 7 (HIGH or CRITICAL)
    modifier onlyCompliant() {
        if (!AEGIS.isCompliant(msg.sender)) revert WalletNonCompliant();
        _;
    }

    /// @notice Softer check — only blocks score = 10 (CRITICAL/sanctioned)
    modifier onlyNotCritical() {
        if (AEGIS.getScore(msg.sender) == 10) revert WalletBlocked();
        _;
    }

    /// @notice Public helper — check compliance status of any address
    function checkCompliance(address wallet) external view returns (
        bool compliant,
        uint8 score,
        uint8 hopDistance,
        uint64 lastChecked,
        bytes32 reasoning
    ) {
        AegisRiskScore.RiskProfile memory p = AEGIS.getRiskProfile(wallet);
        return (p.isCompliant, p.score, p.hopDistance, p.updatedAt, p.reasoning);
    }
}
