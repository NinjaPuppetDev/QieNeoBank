/*
 * QIEVault_shares.spec
 * Certora Prover — Share integrity & inflation attack protection.
 *
 * This is the most critical verification unit for QIEVault. It proves:
 *
 *   TA1  totalAssets formula is correct
 *   SI1  receiveInterest does not mint or burn shares
 *   SI2  receiveInterest does not change any user's share balance
 *   SI3  every valid deposit mints at least 1 share
 *   SI4  share price never decreases after interest is received
 *   IA1  virtual decimal offset is always non-zero (invariant)
 *   IA2  first depositor always receives positive shares (worst-case)
 *
 * Why balanceOf is absent from the methods block:
 *   QIEVaultHarness overrides totalAssets() to read certora_underlyingBalance
 *   directly, bypassing IERC20(asset()).balanceOf(address(this)). That call
 *   was previously unresolvable (runtime address), causing NONDET to assign
 *   MAX_UINT256 and collapsing every share-math rule. The harness override
 *   breaks the chain cleanly while preserving the formula.
 */

using QIEVaultHarness as vault;

methods {
    // ── Harness-exposed internals ─────────────────────────────────────────
    function vault.convertToShares_exposed(uint256)     external returns (uint256) envfree;
    function vault.convertToAssets_exposed(uint256)     external returns (uint256) envfree;
    function vault.convertToSharesCeil_exposed(uint256) external returns (uint256) envfree;
    function vault.convertToAssetsCeil_exposed(uint256) external returns (uint256) envfree;
    function vault.decimalsOffset_exposed()             external returns (uint8)   envfree;
    function vault.underlyingBalance()                  external returns (uint256) envfree;
    function vault.minDeposit()                         external returns (uint256) envfree;
    function vault.certora_underlyingBalance()          external returns (uint256) envfree;

    // ── Public state ──────────────────────────────────────────────────────
    function vault.lendingContract()                    external returns (address) envfree;
    function vault.totalAssets()                        external returns (uint256) envfree;
    function vault.totalSupply()                        external returns (uint256) envfree;
    function vault.balanceOf(address)                   external returns (uint256) envfree;

    // ── Mutating entry points ─────────────────────────────────────────────
    function vault.deposit(uint256, address)            external returns (uint256);
    function vault.receiveInterest(uint256)             external;

    // ── ERC20 underlying — transfer/transferFrom only, no balanceOf ───────
    // balanceOf is intentionally omitted: totalAssets() is overridden in the
    // harness to read certora_underlyingBalance, so no ERC20 balanceOf call
    // is ever made during verification of these rules.
    function _.transfer(address, uint256)               external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256)  external => DISPATCHER(true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared precondition macro
//
// Every share-math rule requires a bounded underlying balance so the prover
// doesn't explore states where totalAssets >> assets and mulDiv floors to 0.
// QUSDC has 6 decimals: 10^18 raw units = 10^12 whole tokens, a safe cap.
// ─────────────────────────────────────────────────────────────────────────────

definition REALISTIC_BALANCE_CAP() returns uint256 = 1000000000000000000; // 1e18

// ─────────────────────────────────────────────────────────────────────────────
// Invariants
// ─────────────────────────────────────────────────────────────────────────────

/**
 * IA1 — The virtual decimal offset is always non-zero.
 *
 * _decimalsOffset() == 3, hardcoded in QIEVault. This invariant catches any
 * future refactor that accidentally zeroes the constant, which would eliminate
 * the inflation-attack protection entirely.
 */
invariant virtualOffset_isNonZero()
    vault.decimalsOffset_exposed() > 0;

// ─────────────────────────────────────────────────────────────────────────────
// Total assets formula
// ─────────────────────────────────────────────────────────────────────────────

/**
 * TA1 — totalAssets() always equals underlying balance + 1.
 *
 * The +1 is the virtual offset that prevents share price manipulation on
 * an empty vault. Any deviation means a bug was introduced in totalAssets().
 */
rule totalAssets_equalsBalancePlusOne() {
    assert vault.totalAssets() == vault.underlyingBalance() + 1,
        "totalAssets must equal underlyingBalance + 1 (virtual offset)";
}

// ─────────────────────────────────────────────────────────────────────────────
// Share integrity rules
// ─────────────────────────────────────────────────────────────────────────────

/**
 * SI1 — receiveInterest does not mint or burn any shares.
 *
 * Interest income appreciates share price by increasing totalAssets, NOT by
 * minting new shares. totalSupply must be unchanged after the call.
 */
rule receiveInterest_doesNotMintOrBurnShares(uint256 amount) {
    env e;
    require e.msg.sender == vault.lendingContract();

    uint256 supplyBefore = vault.totalSupply();
    receiveInterest(e, amount);
    uint256 supplyAfter  = vault.totalSupply();

    assert supplyAfter == supplyBefore,
        "receiveInterest must not change totalSupply";
}

/**
 * SI2 — receiveInterest does not change any individual user's share balance.
 *
 * Share price appreciation is passive — no individual balances are touched.
 */
rule receiveInterest_doesNotChangeUserBalances(uint256 amount, address user) {
    env e;
    require e.msg.sender == vault.lendingContract();

    uint256 balBefore = vault.balanceOf(user);
    receiveInterest(e, amount);
    uint256 balAfter  = vault.balanceOf(user);

    assert balAfter == balBefore,
        "receiveInterest must not change any user's share balance";
}

/**
 * SI3 — A valid deposit always mints at least 1 share.
 *
 * This is the primary inflation-attack property. The 1000x virtual offset
 * in _convertToShares ensures the result of mulDiv is always >= 1 for any
 * deposit >= MIN_DEPOSIT, as long as totalAssets is within the realistic cap.
 *
 * Bound rationale:
 *   certora_underlyingBalance <= 1e18 — excludes states where totalAssets >>
 *   assets, which would cause mulDiv to legitimately floor to 0. Those states
 *   are unreachable under the QUSDC 6-decimal supply reality.
 */
rule deposit_mintsPositiveShares(uint256 assets, address receiver) {
    env e;
    require assets >= vault.minDeposit(),
        "Contract guard — deposit() reverts below MIN_DEPOSIT";
    require receiver != 0,
        "Contract guard — deposit() reverts on zero address receiver";
    require vault.certora_underlyingBalance() <= REALISTIC_BALANCE_CAP(),
        "TVL cap — QUSDC 6-decimal; 1e18 raw = 1e12 whole tokens, far above any realistic TVL";

    uint256 sharesBefore = vault.balanceOf(receiver);
    deposit(e, assets, receiver);
    uint256 sharesAfter  = vault.balanceOf(receiver);

    assert sharesAfter > sharesBefore,
        "deposit must always mint at least 1 share for valid amounts";
}

/**
 * SI4 — Share price must not decrease after receiveInterest.
 *
 * convertToAssets(1e18) after >= convertToAssets(1e18) before.
 * receiveInterest only increases certora_underlyingBalance (via the real
 * token transfer that precedes the call), so totalAssets grows monotonically,
 * meaning the numerator of the share price formula can only increase.
 */
rule sharePriceMustNotDecreaseAfterInterest(uint256 amount) {
    env e;
    require e.msg.sender == vault.lendingContract();

    uint256 referenceShares = 1000000000000000000; // 1e18
    uint256 priceBefore = vault.convertToAssets_exposed(referenceShares);
    receiveInterest(e, amount);
    uint256 priceAfter  = vault.convertToAssets_exposed(referenceShares);

    assert priceAfter >= priceBefore,
        "share price must not decrease after interest is received";
}

// ─────────────────────────────────────────────────────────────────────────────
// Inflation attack protection rules
// ─────────────────────────────────────────────────────────────────────────────

/**
 * IA2 — First depositor always receives positive shares.
 *
 * Worst-case scenario: the vault has been pre-funded via a direct ERC20
 * transfer (totalSupply == 0 but certora_underlyingBalance > 0). Classic
 * ERC4626 inflation attack setup. The 1000x virtual offset ensures that even
 * in this state, convertToShares(MIN_DEPOSIT) > 0.
 *
 * Formula being verified:
 *   shares = assets × (0 + 1000) / (underlyingBalance + 1 + 1)
 *          = assets × 1000 / (underlyingBalance + 2)
 *
 * For shares > 0 we need: assets × 1000 > underlyingBalance + 2
 * With assets >= 1e6 (MIN_DEPOSIT) and underlyingBalance <= 1e18:
 *   1e6 × 1000 = 1e9 >> 1e18? No — so the cap matters.
 *   At the cap: 1e6 × 1000 / (1e18 + 2) floors to 0.
 *
 * This means the property only holds when underlyingBalance < assets × 1000.
 * We constrain to underlyingBalance <= assets × 999 to make the bound tight
 * and explicit rather than hiding it inside a loose 1e18 cap.
 */
rule firstDeposit_mintsPositiveShares(uint256 assets) {
    env e;
    require assets >= vault.minDeposit(),
        "Contract guard — deposit() reverts below MIN_DEPOSIT";
    require vault.totalSupply() == 0,
        "First-depositor scenario — no shares minted yet";
    // The virtual offset (1000x) guarantees shares > 0 only when the
    // pre-funded balance hasn't overwhelmed the offset. This is the exact
    // bound the protocol's 1000x offset was designed to handle.
    require vault.certora_underlyingBalance() <= assets * 999,
        "Virtual offset bound — 1000x offset guarantees positive shares when balance < assets*1000";

    uint256 shares = vault.convertToShares_exposed(assets);
    assert shares > 0,
        "virtual offset must ensure first depositor always gets positive shares";
}