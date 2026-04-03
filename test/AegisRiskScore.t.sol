// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AegisRiskScore} from "@/AegisRiskScore.sol";

contract AegisRiskScoreTest is Test {
    AegisRiskScore aegis;
    address backend = address(0xBEEF);
    address wallet = address(0x1234);

    function setUp() public {
        aegis = new AegisRiskScore();
        aegis.authorizeBackend(backend);
    }

    function test_UpdateScore() public {
        vm.prank(backend);
        bytes32[4] memory flags;
        flags[0] = "mixer_exposure";
        aegis.updateRiskScore(wallet, 8, flags, "Direct mixer contact", 1);

        AegisRiskScore.RiskProfile memory p = aegis.getRiskProfile(wallet);
        assertEq(p.score, 8);
        assertEq(uint(p.level), uint(AegisRiskScore.RiskLevel.HIGH));
        assertFalse(p.isCompliant);
    }

    function test_KnownClean_AlwaysScore1() public {
        aegis.addKnownClean(wallet);
        vm.prank(backend);
        bytes32[4] memory flags;
        aegis.updateRiskScore(wallet, 9, flags, "test", 0);
        assertEq(aegis.getScore(wallet), 1);
        assertTrue(aegis.isCompliant(wallet));
    }

    function test_NeverScored_IsCompliant() public view {
        assertTrue(aegis.isCompliant(address(0x9999)));
    }

    function test_UnauthorizedBackend_Reverts() public {
        vm.prank(address(0xDEAD));
        bytes32[4] memory flags;
        vm.expectRevert(AegisRiskScore.UnauthorizedBackend.selector);
        aegis.updateRiskScore(wallet, 5, flags, "test", 3);
    }

    function test_AllScoreLevels() public {
        vm.startPrank(backend);
        bytes32[4] memory flags;

        aegis.updateRiskScore(wallet, 1, flags, "", 99);
        assertEq(uint(aegis.getRiskProfile(wallet).level), uint(AegisRiskScore.RiskLevel.VERY_LOW));

        aegis.updateRiskScore(wallet, 3, flags, "", 4);
        assertEq(uint(aegis.getRiskProfile(wallet).level), uint(AegisRiskScore.RiskLevel.LOW));

        aegis.updateRiskScore(wallet, 6, flags, "", 3);
        assertEq(uint(aegis.getRiskProfile(wallet).level), uint(AegisRiskScore.RiskLevel.MEDIUM));

        aegis.updateRiskScore(wallet, 9, flags, "", 1);
        assertEq(uint(aegis.getRiskProfile(wallet).level), uint(AegisRiskScore.RiskLevel.HIGH));

        aegis.updateRiskScore(wallet, 10, flags, "", 0);
        assertEq(uint(aegis.getRiskProfile(wallet).level), uint(AegisRiskScore.RiskLevel.CRITICAL));

        vm.stopPrank();
    }
}
