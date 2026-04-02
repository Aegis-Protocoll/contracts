// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AegisRiskScore} from "../src/AegisRiskScore.sol";
import {MockDeFiProtocol} from "../src/MockDeFiProtocol.sol";
import {AegisGuard} from "../src/AegisGuard.sol";

contract AegisGuardTest is Test {
    AegisRiskScore aegis;
    MockDeFiProtocol defi;

    address backend     = address(0xBEEF);
    address cleanWallet = address(0x1111);
    address riskyWallet = address(0x2222);
    address sanctioned  = address(0x3333);

    function setUp() public {
        aegis = new AegisRiskScore();
        defi  = new MockDeFiProtocol(address(aegis));
        aegis.authorizeBackend(backend);

        vm.startPrank(backend);

        bytes32[4] memory noFlags;
        aegis.updateRiskScore(cleanWallet, 2, noFlags, "Low risk wallet", 4);

        bytes32[4] memory riskyFlags;
        riskyFlags[0] = "mixer_exposure";
        riskyFlags[1] = "rapid_movement";
        aegis.updateRiskScore(riskyWallet, 8, riskyFlags, "Direct mixer contact", 1);

        bytes32[4] memory sanctionedFlags;
        sanctionedFlags[0] = "sanctions";
        aegis.updateRiskScore(sanctioned, 10, sanctionedFlags, "OFAC sanctioned", 0);

        vm.stopPrank();
    }

    function test_CleanWallet_CanDeposit() public {
        vm.deal(cleanWallet, 1 ether);
        vm.prank(cleanWallet);
        defi.deposit{value: 0.1 ether}();
        assertEq(defi.deposits(cleanWallet), 0.1 ether);
    }

    function test_RiskyWallet_CannotDeposit() public {
        vm.deal(riskyWallet, 1 ether);
        vm.prank(riskyWallet);
        vm.expectRevert(AegisGuard.WalletNonCompliant.selector);
        defi.deposit{value: 0.1 ether}();
    }

    function test_RiskyWallet_CanSwap() public {
        vm.prank(riskyWallet);
        uint256 out = defi.swap(1 ether);
        assertEq(out, 0.98 ether);
    }

    function test_SanctionedWallet_CannotSwap() public {
        vm.prank(sanctioned);
        vm.expectRevert(AegisGuard.WalletBlocked.selector);
        defi.swap(1 ether);
    }

    function test_AnyoneCanWithdraw() public {
        vm.deal(cleanWallet, 1 ether);
        vm.prank(cleanWallet);
        defi.deposit{value: 0.5 ether}();

        uint256 before = cleanWallet.balance;
        vm.prank(cleanWallet);
        defi.withdraw();
        assertGt(cleanWallet.balance, before);
    }

    function test_ScoreUpdate_UnblocksWallet() public {
        vm.deal(riskyWallet, 1 ether);

        vm.prank(riskyWallet);
        vm.expectRevert(AegisGuard.WalletNonCompliant.selector);
        defi.deposit{value: 0.1 ether}();

        vm.prank(backend);
        bytes32[4] memory noFlags;
        aegis.updateRiskScore(riskyWallet, 3, noFlags, "Risk cleared", 4);

        vm.prank(riskyWallet);
        defi.deposit{value: 0.1 ether}();
        assertEq(defi.deposits(riskyWallet), 0.1 ether);
    }
}
