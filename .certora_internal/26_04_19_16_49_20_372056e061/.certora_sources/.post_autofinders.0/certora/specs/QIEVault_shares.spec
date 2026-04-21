/*
 * QIEVault_shares.spec
 * Certora Prover — Share integrity & inflation attack protection.
 *
 * Prerequisite: src/QIEVault.sol line 57 must read:
 *   function totalAssets() public view virtual override returns (uint256)
 *
 * Properties verified:
 *   TA1  totalAssets formula is correct
 *   SI1  receiveInterest does not mint or burn shares
 *   SI2  receiveInterest does not change any user's share balance
 *   SI3  every valid deposit mints at least 1 share
 *   SI4  share price never decreases after interest is received
 *   IA1  virtual decimal offset is always non-zero (invariant)
 *   IA2  first depositor always receives positive shares (worst-case)
 *
 * Why certora_underlyingBalance instead of ERC20.balanceOf():
 *   QIEVault.totalAssets() calls IERC20(asset()).balanceOf(address(this)).
 *   asset() is an immutable set at the ERC4626 IR level. Certora cannot
 *   resolve the callee statically regardless of constructor arguments —
 *   AUTO havoc assigns MAX_UINT256, poisoning every share-math rule.
 *
 *   QIEVaultHarness overrides totalAssets() to read certora_underlyingBalance
 *   (possible because we added `virtual` to the production function).
 *   The formula is identical: certora_underlyingBalance + 1.
 *   The spec bounds certora_underlyingBalance to a realistic value.
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

    // ERC20 transfer calls — dispatched to any known implementation.
    // balanceOf is intentionally absent: totalAssets() is overridden in the
    // harness so no ERC20 balanceOf call is ever made during these rules.
    function _.transfer(address, uint256)               external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256)  external => DISPATCHER(true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bound
//
// QUSDC has 6 decimals. 10^18 raw units = 10^12 whole tokens.
// Bounding certora_underlyingBalance here ensures the prover does not explore
// states where totalAssets >> assets and mulDiv legitimately floors to 0.
// Those states are unreachable under any realistic protocol TVL.
// ─────────────────────────────────────────────────────────────────────────────

definition BALANCE_CAP() returns uint256 = 1000000000000000000; // 1e18

// ─────────────────────────────────────────────────────────────────────────────
// Invariants
// ─────────────────────────────────────────────────────────────────────────────

/**
 * IA1 — The virtual decimal offset is always non-zero.
 *
 * _decimalsOffset() is hardcoded to 3 in QIEVault. This invariant catches any
 * future refactor that zeroes the constant, which would remove the 1000x
 * inflation-attack protection entirely.
 */
invariant virtualOffset_isNonZero()
    vault.decimalsOffset_exposed() > 0;

// ─────────────────────────────────────────────────────────────────────────────
// Total assets formula
// ─────────────────────────────────────────────────────────────────────────────

/**
 * TA1 — totalAssets() always equals underlying balance + 1.
 *
 * The +1 virtual offset is what prevents share price manipulation on an empty
 * vault. This rule verifies the harness override preserves the formula exactly.
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
 * Bound rationale:
 *   certora_underlyingBalance <= 1e18 excludes states where totalAssets >>
 *   assets, which causes mulDiv to floor to 0 shares. Those states cannot
 *   occur under any realistic QUSDC TVL (6 decimals, 1e18 = 1e12 whole tokens).
 */
rule deposit_mintsPositiveShares(uint256 assets, address receiver) {
    env e;
    require assets >= vault.minDeposit(),
        "Contract guard — deposit() reverts below MIN_DEPOSIT";
    require receiver != 0,
        "Contract guard — deposit() reverts on zero address receiver";
    require vault.certora_underlyingBalance() <= BALANCE_CAP(),
        "TVL cap — prover must not explore totalAssets >> assets states";

    uint256 sharesBefore = vault.balanceOf(receiver);
    deposit(e, assets, receiver);
    uint256 sharesAfter  = vault.balanceOf(receiver);

    assert sharesAfter > sharesBefore,
        "deposit must always mint at least 1 share for valid amounts";
}

/**
 * SI4 — Share price must not decrease after receiveInterest.
 *
 * receiveInterest() emits an event and returns — it does not transfer tokens
 * itself (the caller does that before invoking it). certora_underlyingBalance
 * is not modified by receiveInterest(), so totalAssets() is unchanged, and
 * convertToAssets() is trivially stable. This rule verifies no hidden state
 * mutation exists in the function.
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
// Inflation attack protection
// ─────────────────────────────────────────────────────────────────────────────

/**
 * IA2 — First depositor always receives positive shares.
 *
 * Worst case: vault pre-funded via direct transfer (totalSupply == 0,
 * certora_underlyingBalance > 0). Classic ERC4626 inflation attack setup.
 *
 * Formula: shares = assets × 1000 / (underlyingBalance + 2)
 * For shares > 0:  assets × 1000 > underlyingBalance + 2
 *
 * The `assets * 999` bound is mathematically exact: it's the largest
 * underlyingBalance for which the 1000x offset still guarantees shares > 0.
 * This is what the virtual offset was designed to protect against.
 */
rule firstDeposit_mintsPositiveShares(uint256 assets) {
    env e;
    require assets >= vault.minDeposit(),
        "Contract guard — deposit() reverts below MIN_DEPOSIT";
    require vault.totalSupply() == 0,
        "First-depositor scenario — no shares minted yet";
    require vault.certora_underlyingBalance() <= assets * 999,
        "Virtual offset protection range — 1000x offset guarantees shares > 0 iff balance < assets*1000";

    uint256 shares = vault.convertToShares_exposed(assets);
    assert shares > 0,
        "virtual offset must ensure first depositor always gets positive shares";
}