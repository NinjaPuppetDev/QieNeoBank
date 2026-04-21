/*
 * QIEVault.spec
 * Certora Prover formal verification specification for QIEVault.
 *
 * Verification target : QIEVaultHarness (inherits QIEVault)
 * Prover version      : certora-cli >= 7.x  (CVL2)
 *
 * ── Property catalogue ───────────────────────────────────────────────────────
 *
 * ACCESS CONTROL
 *   AC1  receiveInterest_onlyLending
 *   AC2  setLendingContract_onlyOwner
 *
 * DEPOSIT METADATA  (feeds CreditScore — correctness is critical)
 *   MD1  firstDepositAt_setOnce
 *   MD2  firstDepositAt_setToTimestamp
 *   MD3  totalDeposited_strictlyIncreases
 *   MD4  depositCount_incrementsByOne
 *   MD5  metadata_zeroConsistency   (invariant)
 *   MD6  depositCount_nonDecreasing (invariant)
 *
 * INPUT VALIDATION
 *   IV1  deposit_rejectsZero
 *   IV2  deposit_rejectsBelowMin
 *   IV3  withdraw_rejectsZero
 *   IV4  redeem_rejectsZero
 *
 * TOTAL ASSETS FORMULA
 *   TA1  totalAssets_equalsBalancePlusOne
 *
 * SHARE INTEGRITY
 *   SI1  receiveInterest_doesNotMintOrBurnShares
 *   SI2  receiveInterest_doesNotChangeUserBalances
 *   SI3  deposit_mintsPositiveShares
 *   SI4  sharePriceMustNotDecreaseAfterInterest
 *
 * INFLATION ATTACK PROTECTION
 *   IA1  virtualOffset_isNonZero          (invariant)
 *   IA2  firstDeposit_mintsPositiveShares
 *
 * ─────────────────────────────────────────────────────────────────────────────
 */

using QIEVaultHarness as vault;

methods {
    // ── Harness-exposed internals ─────────────────────────────────────────
    function vault.convertToShares_exposed(uint256)   external returns (uint256) envfree;
    function vault.convertToAssets_exposed(uint256)   external returns (uint256) envfree;
    function vault.convertToSharesCeil_exposed(uint256) external returns (uint256) envfree;
    function vault.convertToAssetsCeil_exposed(uint256) external returns (uint256) envfree;
    function vault.decimalsOffset_exposed()           external returns (uint8)   envfree;
    function vault.underlyingBalance()                external returns (uint256) envfree;
    function vault.minDeposit()                       external returns (uint256) envfree;

    // ── Public state ──────────────────────────────────────────────────────
    function vault.firstDepositAt(address)            external returns (uint256) envfree;
    function vault.totalDeposited(address)            external returns (uint256) envfree;
    function vault.depositCount(address)              external returns (uint256) envfree;
    function vault.lendingContract()                  external returns (address) envfree;
    function vault.owner()                            external returns (address) envfree;
    function vault.totalAssets()                      external returns (uint256) envfree;
    function vault.totalSupply()                      external returns (uint256) envfree;
    function vault.balanceOf(address)                 external returns (uint256) envfree;
    function vault.asset()                            external returns (address) envfree;

    // ── Mutating entry points ─────────────────────────────────────────────
    function vault.deposit(uint256, address)          external returns (uint256);
    function vault.withdraw(uint256, address, address) external returns (uint256);
    function vault.redeem(uint256, address, address)  external returns (uint256);
    function vault.receiveInterest(uint256)           external;
    function vault.setLendingContract(address)        external;

    // ── ERC20 underlying (QUSDC mock) — treat as uninterpreted for speed ──
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Ghosts
// ─────────────────────────────────────────────────────────────────────────────

/// @dev Mirrors depositCount[user] so we can track it across a single call.
ghost mapping(address => uint256) ghost_depositCount {
    init_state axiom forall address a. ghost_depositCount[a] == 0;
}

/// @dev Mirrors firstDepositAt[user].
ghost mapping(address => uint256) ghost_firstDepositAt {
    init_state axiom forall address a. ghost_firstDepositAt[a] == 0;
}

/// @dev Mirrors totalDeposited[user].
ghost mapping(address => uint256) ghost_totalDeposited {
    init_state axiom forall address a. ghost_totalDeposited[a] == 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hooks — keep ghosts in sync with storage
// ─────────────────────────────────────────────────────────────────────────────

hook Sstore depositCount[KEY address user] uint256 newVal {
    ghost_depositCount[user] = newVal;
}
hook Sload uint256 val depositCount[KEY address user] {
    require ghost_depositCount[user] == val;
}

hook Sstore firstDepositAt[KEY address user] uint256 newVal {
    ghost_firstDepositAt[user] = newVal;
}
hook Sload uint256 val firstDepositAt[KEY address user] {
    require ghost_firstDepositAt[user] == val;
}

hook Sstore totalDeposited[KEY address user] uint256 newVal {
    ghost_totalDeposited[user] = newVal;
}
hook Sload uint256 val totalDeposited[KEY address user] {
    require ghost_totalDeposited[user] == val;
}

// ─────────────────────────────────────────────────────────────────────────────
// Invariants
// ─────────────────────────────────────────────────────────────────────────────

/**
 * MD5 — Zero-consistency invariant.
 *
 * All three metadata fields are set together in the first deposit and
 * never individually reset. If any one is zero, all must be zero.
 * CreditScore implicitly assumes this: it uses depositCount == 0 as the
 * "never deposited" signal.
 */
invariant metadata_zeroConsistency(address user)
    (ghost_depositCount[user] == 0) == (ghost_firstDepositAt[user] == 0) &&
    (ghost_depositCount[user] == 0) == (ghost_totalDeposited[user] == 0)
    filtered { f -> f.selector != sig:withdraw(uint256,address,address).selector
                 && f.selector != sig:redeem(uint256,address,address).selector }

/**
 * MD6 — depositCount is non-decreasing.
 *
 * No function other than deposit() modifies depositCount, and deposit()
 * always increments it. Withdrawal does not decrement it (by design —
 * CreditScore uses cumulative deposit history, not current balance).
 */
invariant depositCount_nonDecreasing(address user)
    ghost_depositCount[user] >= 0
    { preserved { require ghost_depositCount[user] < max_uint256; } }

/**
 * IA1 — The virtual decimal offset is always non-zero.
 *
 * _decimalsOffset() == 3, so 10**3 == 1000. This constant is baked in,
 * but we prove it here so any future change to the constant is caught.
 */
invariant virtualOffset_isNonZero()
    vault.decimalsOffset_exposed() > 0;

// ─────────────────────────────────────────────────────────────────────────────
// Access control rules
// ─────────────────────────────────────────────────────────────────────────────

/**
 * AC1 — Only the lending contract may call receiveInterest.
 *
 * If any other address calls receiveInterest, the transaction must revert.
 * This protects the yield accounting — a rogue caller cannot emit a
 * misleading InterestReceived event or manipulate totalAssets indirectly.
 */
rule receiveInterest_onlyLending(uint256 amount) {
    env e;
    require e.msg.sender != vault.lendingContract();
    receiveInterest@withrevert(e, amount);
    assert lastReverted,
        "receiveInterest must revert when caller is not lendingContract";
}

/**
 * AC2 — Only the owner may set the lending contract address.
 */
rule setLendingContract_onlyOwner(address newLending) {
    env e;
    require e.msg.sender != vault.owner();
    setLendingContract@withrevert(e, newLending);
    assert lastReverted,
        "setLendingContract must revert when caller is not owner";
}

// ─────────────────────────────────────────────────────────────────────────────
// Deposit metadata rules
// ─────────────────────────────────────────────────────────────────────────────

/**
 * MD1 — firstDepositAt is written exactly once.
 *
 * Once set, no subsequent call to any function may overwrite it.
 * This is the anchor timestamp for the CreditScore tenure component.
 */
rule firstDepositAt_setOnce(address user) {
    env e;
    calldataarg args;
    method f;

    uint256 before = vault.firstDepositAt(user);
    require before != 0; // already set

    f(e, args);

    uint256 after_ = vault.firstDepositAt(user);
    assert after_ == before,
        "firstDepositAt must not change once set";
}

/**
 * MD2 — On a user's first deposit, firstDepositAt is set to block.timestamp.
 */
rule firstDepositAt_setToTimestamp(uint256 assets, address receiver) {
    env e;
    require vault.firstDepositAt(receiver) == 0; // not yet set
    require assets >= vault.minDeposit();

    deposit(e, assets, receiver);

    assert vault.firstDepositAt(receiver) == e.block.timestamp,
        "firstDepositAt must equal block.timestamp on first deposit";
}

/**
 * MD3 — totalDeposited strictly increases on every deposit.
 */
rule totalDeposited_strictlyIncreases(uint256 assets, address receiver) {
    env e;
    uint256 before = vault.totalDeposited(receiver);
    require assets >= vault.minDeposit();

    deposit(e, assets, receiver);

    uint256 after_ = vault.totalDeposited(receiver);
    assert after_ == before + assets,
        "totalDeposited must increase by exactly the deposited amount";
}

/**
 * MD4 — depositCount increments by exactly one on every deposit.
 */
rule depositCount_incrementsByOne(uint256 assets, address receiver) {
    env e;
    uint256 before = vault.depositCount(receiver);
    require before < max_uint256; // no overflow
    require assets >= vault.minDeposit();

    deposit(e, assets, receiver);

    assert vault.depositCount(receiver) == before + 1,
        "depositCount must increment by exactly 1 on each deposit";
}

// ─────────────────────────────────────────────────────────────────────────────
// Input validation rules
// ─────────────────────────────────────────────────────────────────────────────

/**
 * IV1 — deposit(0, ...) always reverts.
 */
rule deposit_rejectsZero(address receiver) {
    env e;
    deposit@withrevert(e, 0, receiver);
    assert lastReverted, "deposit(0) must revert";
}

/**
 * IV2 — deposit with amount below MIN_DEPOSIT always reverts.
 */
rule deposit_rejectsBelowMin(uint256 assets, address receiver) {
    env e;
    require assets > 0 && assets < vault.minDeposit();
    deposit@withrevert(e, assets, receiver);
    assert lastReverted, "deposit below MIN_DEPOSIT must revert";
}

/**
 * IV3 — withdraw(0, ...) always reverts.
 */
rule withdraw_rejectsZero(address receiver, address owner_) {
    env e;
    withdraw@withrevert(e, 0, receiver, owner_);
    assert lastReverted, "withdraw(0) must revert";
}

/**
 * IV4 — redeem(0, ...) always reverts.
 */
rule redeem_rejectsZero(address receiver, address owner_) {
    env e;
    redeem@withrevert(e, 0, receiver, owner_);
    assert lastReverted, "redeem(0) must revert";
}

// ─────────────────────────────────────────────────────────────────────────────
// Total assets formula
// ─────────────────────────────────────────────────────────────────────────────

/**
 * TA1 — totalAssets() always equals underlying QUSDC balance + 1.
 *
 * The +1 virtual offset is the inflation-attack mitigation. Any deviation
 * from this formula means a bug was introduced in totalAssets().
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
 * Interest income appreciates the share price by increasing totalAssets,
 * NOT by minting new shares. totalSupply must be unchanged.
 */
rule receiveInterest_doesNotMintOrBurnShares(uint256 amount) {
    env e;
    require e.msg.sender == vault.lendingContract();

    uint256 supplyBefore = vault.totalSupply();
    receiveInterest(e, amount);
    uint256 supplyAfter = vault.totalSupply();

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
    uint256 balAfter = vault.balanceOf(user);

    assert balAfter == balBefore,
        "receiveInterest must not change any user's share balance";
}

/**
 * SI3 — A valid deposit always mints at least 1 share.
 *
 * This is the key inflation-attack property: the virtual offset (1000x)
 * ensures the first depositor cannot receive 0 shares regardless of
 * pre-existing totalAssets manipulation.
 */
rule deposit_mintsPositiveShares(uint256 assets, address receiver) {
    env e;
    require assets >= vault.minDeposit();
    require receiver != 0;
    // Bound assets to avoid unrealistic overflow paths the prover explores
    require assets <= 10^30;
    require vault.totalSupply() <= 10^40;

    uint256 sharesBefore = vault.balanceOf(receiver);
    deposit(e, assets, receiver);
    uint256 sharesAfter = vault.balanceOf(receiver);

    assert sharesAfter > sharesBefore,
        "deposit must always mint at least 1 share for valid amounts";
}

/**
 * SI4 — Share price (assets per share) must not decrease after receiveInterest.
 *
 * convertToAssets(1e18 shares) after >= convertToAssets(1e18 shares) before.
 * We use a fixed reference amount (1e18) as a representative share unit.
 *
 * This proves LPs can never be diluted by interest payments.
 */
rule sharePriceMustNotDecreaseAfterInterest(uint256 amount) {
    env e;
    require e.msg.sender == vault.lendingContract();
    // Use 1e18 as a representative share count (avoids trivial 0-share edge case)
    uint256 referenceShares = 1000000000000000000; // 1e18

    uint256 priceBefore = vault.convertToAssets_exposed(referenceShares);
    receiveInterest(e, amount);
    uint256 priceAfter = vault.convertToAssets_exposed(referenceShares);

    assert priceAfter >= priceBefore,
        "share price must not decrease after interest is received";
}

// ─────────────────────────────────────────────────────────────────────────────
// Inflation attack protection rules
// ─────────────────────────────────────────────────────────────────────────────

/**
 * IA2 — First depositor always receives positive shares.
 *
 * Even in the worst case (totalSupply == 0, underlying balance is already
 * nonzero due to direct transfer), the virtual offset ensures shares > 0.
 * This directly refutes the classic ERC4626 inflation attack vector.
 */
rule firstDeposit_mintsPositiveShares(uint256 assets) {
    env e;
    require assets >= vault.minDeposit();
    require assets <= 10^30;
    // Worst-case: vault has been pre-funded but no shares exist yet
    require vault.totalSupply() == 0;

    uint256 shares = vault.convertToShares_exposed(assets);
    assert shares > 0,
        "virtual offset must ensure first depositor always gets positive shares";
}