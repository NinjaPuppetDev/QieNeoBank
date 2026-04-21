# QIENeobank

**Undercollateralized lending on QIE Blockchain — powered by on-chain credit scoring and soulbound identity.**

QIENeobank is a DeFi neobank that lets users build a verifiable credit history on-chain and access undercollateralized loans based on their behavior — not their collateral. It is built natively on the QIE Blockchain (Chain ID 1990) and integrates QIE Pass for KYC identity verification.

---

## Mainnet Deployment — QIE Blockchain (Chain ID 1990)

| Contract | Address |
|---|---|
| QUSDC | `0x3F43DA82eC9A4f5285F10FaF1F26EcA7319E5DA5` |
| QIEVault | `0x25aCF79194e8A5aAFE71d5Ca90aA0fc633219003` |
| QIEIdentity | `0x764Eb257ca3D0cb88A9990e7c923936597b2Ac7f` |
| QIELending | `0xf2Cc1450929898FfcAd31BDD88D01FD962feFc7E` |
| CreditScore | `0xCd3fC2ff780fE1C5Adc07A0A330445DD5E0527d5` |
| QIENeobank | `0x11283016A8f298d01E2D6a2020ac3d751FC754A7` |
| Treasury | `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38` |

Deployment blocks: `7289247–7289257`
Explorer: [mainnet.qie.digital](https://mainnet.qie.digital/)

---

## The Problem

Over 1.7 billion people globally are unbanked or underbanked — not because they are bad credit risks, but because they have no credit history that traditional financial institutions recognize. DeFi has largely replicated the same collateral-first model, requiring users to over-collateralize loans with assets they already own, which defeats the purpose for people who need liquidity.

---

## What QIENeobank Does

QIENeobank creates an on-chain credit identity for each user based on their actual financial behavior: how long they have been saving, how consistently they deposit, and how reliably they repay loans. This score determines their loan tier, interest rate, and how much they can borrow without collateral.

A user who has never accessed formal credit can start with a Basic identity, deposit QUSDC into the vault, build a track record over time, and eventually qualify for unsecured loans — all transparently on-chain, with no bank account required.

---

## Architecture

The protocol is composed of five deployed contracts that interact through a single user-facing facade (QIENeobank):

**QIEVault** is an ERC-4626 yield vault. Users deposit QUSDC and receive vault shares. The vault tracks per-user deposit history (first deposit timestamp, total deposited, deposit count) which feeds directly into the credit scoring model. Interest from loan repayments flows back into the vault, appreciating the share price for all depositors.

**QIEIdentity** is a soulbound ERC-721 identity passport. It is non-transferable and tied to a user's biometric and document hashes verified through QIE Pass (the QIE blockchain's KYC Chrome extension wrapping Sumsub). The contract supports four identity tiers — Basic, Verified, Enhanced, and Institutional — each unlocking progressively larger loan limits and unsecured access. It implements canonical passport IDs that persist across revocation cycles, meaning a user's credit history survives wallet rotation. Document uniqueness and 90-day revocation cooldowns are enforced on-chain.

**CreditScore** computes a 300–850 score from five weighted components derived entirely from on-chain data:

| Component | Max Points | Weight | Source |
|---|---|---|---|
| Tenure | 100 | 18% | `firstDepositAt` in QIEVault |
| Volume | 100 | 18% | `totalDeposited` (7-day aged) |
| Activity | 100 | 18% | `depositCount` (7-day aged) |
| Accuracy | 200 | 36% | On-time repayment rate from QIELending |
| Consistency | 50 | 9% | Regular saving pattern |

The 7-day aging requirement on volume and activity prevents score manipulation through same-day flash deposits.

**QIELending** manages the full loan lifecycle: origination, interest accrual, repayment, liquidation, and bad debt declaration. Loan terms are tier-gated:

| Tier | Score Range | Max Loan | APR | Unsecured |
|---|---|---|---|---|
| Bronze | 300–549 | $1,000 | 25% | No |
| Silver | 550–649 | $5,000 | 18% | Yes |
| Gold | 650–749 | $20,000 | 12% | Yes |
| Platinum | 750+ | $50,000 | 8% | Yes |

All fee parameters (origination, liquidation, late fees, protocol interest share) are configurable on-chain and read live by the frontend — nothing is hardcoded in the UI.

**QIENeobank** is the user-facing facade contract. It aggregates reads from all underlying contracts into single view calls (`getAccount`, `getLoanTerms`, `getLoanDetails`, `getScoreBreakdown`) to minimize RPC calls from the frontend, and routes all user actions (deposit, withdraw, requestLoan, repayLoan, addLiquidity) through a single trusted entry point.

---

## QIE Pass Integration

QIEIdentity acts as a relying party to QIE Pass, the QIE blockchain's KYC infrastructure. The identity contract exposes `linkQIEAttestation` which verifies a QIE Pass signature on-chain before recording the attestation. The frontend checks `hasValidQIEAttestation` and `isVerified` before rendering the KYC gate, and the KYCGate component manages the full relying-party flow without custom KYC orchestration.

Supported countries span Latin America, North America, Spain, Portugal, Morocco, and the Caribbean — 37 jurisdictions initialized in the constructor.

---

## Frontend

- **Framework:** Next.js 16 (App Router, Turbopack)
- **Wallet:** RainbowKit + Wagmi + Viem
- **Chains:** QIE Mainnet (primary) + Anvil (local dev)
- **Transport:** Viem `fallback()` across all 5 QIE mainnet RPC endpoints for resilience
- **UI:** Tailwind CSS with a financial dark aesthetic, Framer Motion animations
- **State:** All contract reads use `useReadContract` with tuple-typed return values matched exactly to Solidity struct positions. Multi-step transactions (approve → action) are chained via `useWaitForTransactionReceipt` + `useEffect`.

The RainbowKit/Wagmi config is lazily initialized client-side only to avoid the `indexedDB is not defined` SSR error from WalletConnect's storage layer.

---

## Smart Contract Security Notes

- `QIEIdentity` uses `Ownable2Step` for all admin functions — ownership transfers require two-step confirmation.
- Soulbound enforcement is applied to both `QIEIdentity` and `QIEBadDebt` via `_update` override, blocking all transfers while allowing mint and burn.
- The canonical passport ID system ensures that bad debt history tracked in `QIEBadDebt` survives revocation and wallet rotation — a user cannot escape their default history by re-registering with the same biometrics.
- `QIEBadDebt` (soulbound bad debt NFT) is implemented and tested but not yet deployed on mainnet. It is downstream of `declareBadDebt` in `QIELending` and does not affect the core deposit/loan/repay flow for the hackathon demo.

---

## Local Development

```bash
# Install dependencies
pnpm install

# Run frontend
pnpm dev

# Deploy to local Anvil
forge script script/TestDeployScript.s.sol:TestDeployScript \
  --rpc-url http://127.0.0.1:8545 \
  --account anvilwallet \
  --broadcast

# Deploy to QIE Mainnet
forge script script/DeployScript.s.sol:DeployScript \
  --rpc-url https://rpc2mainnet.qie.digital/ \
  --account qieneobank \
  --broadcast \
  --with-gas-price 2000000001 \
  --slow
```

**Environment variables required:**
```
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

---

## QIE Network Configuration

| Parameter | Value |
|---|---|
| Chain ID | 1990 |
| Symbol | QIEV3 |
| RPC 1 | https://rpc1mainnet.qie.digital/ |
| RPC 2 | https://rpc2mainnet.qie.digital/ |
| RPC 3 | https://rpc5mainnet.qie.digital/ |
| RPC 4 | https://rpc4mainnet.qie.digital/ |
| RPC 5 | https://rpc3mainnet.qie.digital/ |
| Explorer | https://mainnet.qie.digital/ |

---

## Stack

Solidity 0.8.24 · OpenZeppelin 5 · Foundry · Next.js 16 · Wagmi v2 · Viem v2 · RainbowKit · Tailwind CSS · Framer Motion · pnpm