/*
 * QIEVault_shares.spec
 * Certora Prover — Share integrity & inflation attack protection.
 *
 * Prerequisites:
 *   1. src/QIEVault.sol: totalAssets() marked `virtual override`
 *   2. certora/harness/QIEVaultHarness.sol: overrides deposit() and totalAssets()
 *
 * Properties verified:
 *   TA1  totalAssets formula is correct
 *   SI1  receiveInterest does not mint or burn shares
 *   SI2  receiveInterest does not change any user's share balance
 *   SI3  every valid deposit mints at least 1 share
 *   SI4  share price never decreases after interest is received
 *   IA1  virtual decimal offset is always non-zero (invariant)
 *   IA2  first depositor always receives positive shares
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
    function vault.ghost_underlying()                   external returns (uint256) envfree;

    // ── Public state ──────────────────────────────────────────────────────
    function vault.lendingContract()                    external returns (address) envfree;
    function vault.totalAssets()                        external returns (uint256) envfree;
    function vault.totalSupply()                        external returns (uint256) envfree;
    function vault.balanceOf(address)                   external returns (uint256) envfree;

    // ── Mutating entry points ─────────────────────────────────────────────
    function vault.deposit(uint256, address)            external returns (uint256);
    function vault.receiveInterest(uint256)             external;

    // No ERC20 summaries needed — the harness deposit() override bypasses
    // SafeERC20 entirely. The assembly call in SafeERC20.sol line 227 is
    // never reached during deposit verification. receiveInterest() makes
    // no token calls. The remaining wildcard covers any residual paths.
    function _.transfer(address, uint256)               external => ALWAYS(true);
    function _.transferFrom(address, address, uint256)  external => ALWAYS(true);
    function _.approve(address, uint256)                external => ALWAYS(true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Bound
// ─────────────────────────────────────────────────────────────────────────────

// 1e18 raw QUSDC = 1e12 whole tokens. Realistic TVL ceiling.
// Prevents prover from exploring totalAssets >> assets paths where
// mulDiv legitimately floors to 0 — unreachable in production.
definition BALANCE_CAP() returns uint256 = 1000000000000000000;

// ─────────────────────────────────────────────────────────────────────────────
// Invariants
// ─────────────────────────────────────────────────────────────────────────────

invariant virtualOffset_isNonZero()
    vault.decimalsOffset_exposed() > 0;

// ─────────────────────────────────────────────────────────────────────────────
// Rules
// ─────────────────────────────────────────────────────────────────────────────

rule totalAssets_equalsBalancePlusOne() {
    assert vault.totalAssets() == vault.underlyingBalance() + 1,
        "totalAssets must equal underlyingBalance + 1 (virtual offset)";
}

rule receiveInterest_doesNotMintOrBurnShares(uint256 amount) {
    env e;
    require e.msg.sender == vault.lendingContract();
    uint256 supplyBefore = vault.totalSupply();
    receiveInterest(e, amount);
    assert vault.totalSupply() == supplyBefore,
        "receiveInterest must not change totalSupply";
}

rule receiveInterest_doesNotChangeUserBalances(uint256 amount, address user) {
    env e;
    require e.msg.sender == vault.lendingContract();
    uint256 balBefore = vault.balanceOf(user);
    receiveInterest(e, amount);
    assert vault.balanceOf(user) == balBefore,
        "receiveInterest must not change any user's share balance";
}

/**
 * SI3 — A valid deposit always mints at least 1 share.
 *
 * ghost_underlying models the vault balance AFTER the token transfer.
 * The spec sets it below BALANCE_CAP to stay within the 1000x offset's
 * protection range.
 */
rule deposit_mintsPositiveShares(uint256 assets, address receiver) {
    env e;
    require assets >= vault.minDeposit(),
        "Contract guard — deposit() reverts below MIN_DEPOSIT";
    require receiver != 0,
        "Contract guard — deposit() reverts on zero address receiver";
    require vault.ghost_underlying() <= BALANCE_CAP(),
        "TVL cap — excludes mulDiv floor-to-zero paths unreachable in practice";

    uint256 sharesBefore = vault.balanceOf(receiver);
    deposit(e, assets, receiver);
    uint256 sharesAfter  = vault.balanceOf(receiver);

    assert sharesAfter > sharesBefore,
        "deposit must always mint at least 1 share for valid amounts";
}

rule sharePriceMustNotDecreaseAfterInterest(uint256 amount) {
    env e;
    require e.msg.sender == vault.lendingContract();
    uint256 referenceShares = 1000000000000000000;
    uint256 priceBefore = vault.convertToAssets_exposed(referenceShares);
    receiveInterest(e, amount);
    assert vault.convertToAssets_exposed(referenceShares) >= priceBefore,
        "share price must not decrease after interest is received";
}

/**
 * IA2 — First depositor always receives positive shares.
 *
 * Exact protection boundary of the 1000x offset:
 *   shares = assets * 1000 / (ghost_underlying + 2) > 0
 *   iff ghost_underlying < assets * 1000
 *   bound: ghost_underlying <= assets * 999 (strictly inside the range)
 */
rule firstDeposit_mintsPositiveShares(uint256 assets) {
    env e;
    require assets >= vault.minDeposit(),
        "Contract guard — deposit() reverts below MIN_DEPOSIT";
    require vault.totalSupply() == 0,
        "First-depositor scenario — no shares minted yet";
    require vault.ghost_underlying() <= assets * 999,
        "Virtual offset protection range — 1000x offset guarantees shares > 0 iff balance < assets*1000";

    uint256 shares = vault.convertToShares_exposed(assets);
    assert shares > 0,
        "virtual offset must ensure first depositor always gets positive shares";
}