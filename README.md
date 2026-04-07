# Aegis Protocol — Smart Contracts

> On-chain risk score storage and composable compliance enforcement for HashKey Chain.

**Hackathon:** HashKey Chain Horizon 2026 | **Tracks:** AI + DeFi | **Chain:** HashKey Chain Testnet (133)

[Docs](https://aegisprotocol-1.gitbook.io/aegisprotocol) | [Landing](https://aegis-protocol-landing.vercel.app) | [Demo](https://aegis-protocol-demo.vercel.app) | [API](https://aegis-protocol-api.vercel.app)

---

## Problem

DeFi protocols on HashKey Chain have no composable way to enforce wallet-level compliance. Existing solutions like Range provide off-chain APIs, but enforcement remains the protocol's responsibility — most skip it entirely.

## Solution

Aegis writes AI-generated risk scores directly on-chain. Any DeFi protocol inherits `AegisGuard` and gets automatic enforcement in 2 lines of Solidity. No custom compliance logic needed.

---

## Deployed Contracts

| Contract | Address | Explorer |
|---|---|---|
| AegisRiskScore | `0x4299b716F33Be7F43D0Ebf0c1F4863D3fC4b37ec` | [View](https://testnet-explorer.hsk.xyz/address/0x4299b716F33Be7F43D0Ebf0c1F4863D3fC4b37ec) |
| MockDeFiProtocol | `0xE633d2bBb9D610A3dA777a651C1497257a159557` | [View](https://testnet-explorer.hsk.xyz/address/0xE633d2bBb9D610A3dA777a651C1497257a159557) |

---

## Architecture

### AegisRiskScore.sol — Core Storage

Stores per-wallet `RiskProfile` structs on-chain:

```
struct RiskProfile {
    uint8 score;           // 1-10
    RiskLevel level;       // VERY_LOW → CRITICAL
    uint64 updatedAt;      // unix timestamp
    string[] flags;        // behavioral flags (e.g. "mixer_exposure")
    string reasoning;      // AI-generated explanation
    bool isCompliant;      // score <= 6
    uint8 hopDistance;      // hops to nearest malicious address
}
```

**Access control:**
- `onlyOwner` — admin functions (authorize backends, manage clean list)
- `onlyBackend` — write functions (only authorized backend wallets can update scores)
- Public reads — any contract or EOA can query scores

**Key design decisions:**
- `bytes32[4]` fixed array instead of dynamic `string[]` for gas optimization
- Known clean address override at contract level (score forced to 1)
- Never-scored wallets default to compliant (permissive by default)

### AegisGuard.sol — Composable Base

Abstract contract that DeFi protocols inherit. Provides two enforcement modifiers:

```solidity
contract MyDEX is AegisGuard {
    constructor() AegisGuard(AEGIS_ADDRESS) {}
    function deposit() external payable onlyCompliant { ... }
    function swap(uint256 amt) external onlyNotCritical { ... }
}
```

| Modifier | Threshold | Use Case |
|---|---|---|
| `onlyCompliant` | Blocks score >= 7 | Deposits, lending, bridging |
| `onlyNotCritical` | Blocks score = 10 | Swaps, lighter operations |

This graduated enforcement mirrors real-world compliance — strict for capital inflows, softer for trading, no restriction on withdrawals.

### MockDeFiProtocol.sol — Demo DEX

Demonstrates both enforcement levels:
- `deposit()` — strict (`onlyCompliant`), blocked at score >= 7
- `swap()` — soft (`onlyNotCritical`), blocked only at score 10
- `withdraw()` — no check, users can always exit their funds

---

## Enforcement Matrix

| Score | Level | Compliant | `deposit()` | `swap()` | `withdraw()` |
|---|---|---|---|---|---|
| 10 | CRITICAL | No | Blocked | Blocked | Allowed |
| 7-9 | HIGH | No | Blocked | Allowed | Allowed |
| 4-6 | MEDIUM | Yes | Allowed | Allowed | Allowed |
| 1-3 | LOW/VERY_LOW | Yes | Allowed | Allowed | Allowed |

---

## Tests

```bash
forge test -vvv
```

Test coverage:
- Score update and level mapping across all 5 risk levels
- Known clean address override (score 9 → forced to 1)
- Never-scored wallet defaults to compliant
- Unauthorized backend reverts
- Clean wallet can deposit, risky wallet blocked
- Risky wallet can swap (soft check), sanctioned wallet blocked
- Score update unblocks previously blocked wallet
- Anyone can withdraw regardless of score

---

## Build & Deploy

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge build

source .env
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  --broadcast --chain-id 133 -vvvv
```

## Tech

Solidity 0.8.20 | Foundry | OpenZeppelin Ownable | HashKey Chain (OP-Stack)
