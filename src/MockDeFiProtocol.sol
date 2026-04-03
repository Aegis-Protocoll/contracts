// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AegisGuard} from "@/AegisGuard.sol";

/// @title MockDeFiProtocol
/// @notice Demo protocol showing Aegis integration for the DeFi track.
contract MockDeFiProtocol is AegisGuard {
 error InvalidAmount();
 error NothingToWithdraw();
 error TransferFailed();

 mapping(address => uint256) public deposits;
 uint256 public totalDeposits;

 event Deposited(address indexed user, uint256 amount);
 event Withdrawn(address indexed user, uint256 amount);
 event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut);

 constructor(address _aegisRiskScore) AegisGuard(_aegisRiskScore) {}

 function deposit() external payable onlyCompliant {
  if (msg.value == 0) revert InvalidAmount();
  deposits[msg.sender] += msg.value;
  totalDeposits += msg.value;
  emit Deposited(msg.sender, msg.value);
 }

 function swap(uint256 amountIn) external onlyNotCritical returns (uint256) {
  if (amountIn == 0) revert InvalidAmount();
  uint256 amountOut = (amountIn * 98) / 100;
  emit SwapExecuted(msg.sender, amountIn, amountOut);
  return amountOut;
 }

 function withdraw() external {
  uint256 amount = deposits[msg.sender];
  if (amount == 0) revert NothingToWithdraw();
  deposits[msg.sender] = 0;
  totalDeposits -= amount;
  (bool success,) = msg.sender.call{value: amount}("");
  if (!success) revert TransferFailed();
  emit Withdrawn(msg.sender, amount);
 }
}
