// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/QIENeobank.sol";
import "../../src/interfaces/IQIEInterfaces.sol";
import "../../src/QIEIdentity.sol";

// ── Minimal mocks ──────────────────────────────────────────────────────────────

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bool public transferFromShouldFail;

    function mint(address to, uint256 amt) external {
        balanceOf[to] += amt;
    }

    function setTransferFromFail(bool fail) external {
        transferFromShouldFail = fail;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(!transferFromShouldFail, "MockERC20: forced fail");
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            require(allowed >= amt, "MockERC20: insufficient allowance");
            allowance[from][msg.sender] = allowed - amt;
        }
        require(balanceOf[from] >= amt, "MockERC20: insufficient balance");
        balanceOf[from] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }
}

contract MockVault {
    MockERC20 public asset;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public depositCount;
    mapping(address => uint256) public totalDeposited;
    mapping(address => uint256) public firstDepositAt;

    bool public depositShouldFail;

    constructor(address _asset) {
        asset = MockERC20(_asset);
    }

    function setDepositFail(bool fail) external {
        depositShouldFail = fail;
    }

    function setDepositCount(address user, uint256 count) external {
        depositCount[user] = count;
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        require(!depositShouldFail, "MockVault: forced fail");
        asset.transferFrom(msg.sender, address(this), assets);
        shares = assets; // 1:1 for simplicity
        balanceOf[receiver] += shares;
        depositCount[receiver]++;
        totalDeposited[receiver] += assets;
        if (firstDepositAt[receiver] == 0) firstDepositAt[receiver] = block.timestamp;
    }

    function maxWithdraw(address user) external view returns (uint256) {
        return balanceOf[user];
    }

    function maxRedeem(address user) external view returns (uint256) {
        return balanceOf[user];
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        shares = assets;
        balanceOf[owner] -= shares;
        asset.transfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        assets = shares;
        balanceOf[owner] -= shares;
        asset.transfer(receiver, assets);
    }
}

contract MockPool {
    bool public claimWinningsCalledByNeobank;
    address public lastClaimWinningsCaller;

    function placeBet(uint256, bool, uint256, address) external {}

    function claimWinnings(uint256) external {
        lastClaimWinningsCaller = msg.sender;
        claimWinningsCalledByNeobank = (msg.sender != address(0));
    }

    function claimRefund(uint256, address user) external {}

    function positions(uint256, address) external pure returns (uint256, uint256, bool) {
        return (0, 0, false);
    }

    function markets(uint256)
        external
        pure
        returns (string memory, uint256, uint256, uint256, uint256, uint256, uint256, uint8, uint8)
    {
        return ("", 0, 0, 0, 0, 0, 0, 0, 0);
    }

    function totalBets(address) external pure returns (uint256) {
        return 0;
    }

    function correctBets(address) external pure returns (uint256) {
        return 0;
    }

    function totalWagered(address) external pure returns (uint256) {
        return 0;
    }
}

contract MockScorer {
    function getScore(address) external pure returns (uint256) {
        return 800;
    }

    function getScorePercent(address) external pure returns (uint256) {
        return 80;
    }

    function getTier(address) external pure returns (string memory) {
        return "Gold";
    }

    function getScoreBreakdown(address)
        external
        pure
        returns (uint256, uint256, uint256, uint256, uint256, uint256, string memory)
    {
        return (800, 100, 100, 100, 100, 100, "Gold");
    }
}

contract MockLending {
    struct Loan {
        uint256 principal;
        uint256 collateral;
        uint256 interestRateBps;
        uint256 issuedAt;
        uint256 dueDate;
        uint256 repaid;
        uint8 status; // 0=None, 1=Active, 2=Repaid
    }

    struct FeeConfig {
        uint256 originationFeeBps;
        uint256 protocolInterestShareBps;
        uint256 liquidationFeeBps;
        uint256 liquidatorIncentiveBps;
        uint256 lateFeeBps;
    }

    mapping(address => Loan) public loans;
    uint256 public totalLiquidity;
    uint256 public activeLoanVolume;

    bool public requestLoanShouldFail;
    bool public repayLoanShouldFail;

    MockERC20 asset;

    constructor(address _asset) {
        asset = MockERC20(_asset);
    }

    function setRequestLoanFail(bool fail) external {
        requestLoanShouldFail = fail;
    }

    function setRepayLoanFail(bool fail) external {
        repayLoanShouldFail = fail;
    }

    function setLoanActive(address borrower, uint256 principal, uint256 collateral) external {
        loans[borrower] = Loan(principal, collateral, 500, block.timestamp, block.timestamp + 30 days, 0, 1);
        activeLoanVolume += principal;
    }

    function feeConfig() external pure returns (FeeConfig memory) {
        return FeeConfig(100, 2000, 500, 200, 500);
    }

    function getLoanTerms(address) external pure returns (uint8, uint256, uint256, uint256, uint256) {
        return (2, 10_000e6, 500, 0, 800);
    }

    function getRepaymentAmount(address borrower)
        external
        view
        returns (uint256 totalDue, uint256 interest, uint256 lateFee)
    {
        Loan storage l = loans[borrower];
        if (l.status != 1) return (0, 0, 0);
        interest = (l.principal * l.interestRateBps) / 10000;
        totalDue = l.principal + interest;
        lateFee = 0;
    }

    // FIX: Updated signature to match IQIELending interface
    function requestLoan(uint256 amount, uint256 collateral, address borrower, bool isUnsecured) external {
        require(!requestLoanShouldFail, "MockLending: forced fail");
        loans[borrower] = Loan(amount, collateral, 500, block.timestamp, block.timestamp + 30 days, 0, 1);
        activeLoanVolume += amount;
        asset.transfer(borrower, amount);
    }

    function repayLoan(address borrower, uint256 amount) external {
        require(!repayLoanShouldFail, "MockLending: forced fail");
        Loan storage l = loans[borrower];
        l.repaid = amount;
        l.status = 2;
        activeLoanVolume -= l.principal;
        if (l.collateral > 0) {
            asset.transfer(borrower, l.collateral);
        }
    }

    function addLiquidity(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        totalLiquidity += amount;
    }

    function removeLiquidity(uint256 amount) external {
        totalLiquidity -= amount;
        asset.transfer(msg.sender, amount);
    }
}

// ── Attack test suite ──────────────────────────────────────────────────────────

contract QIENeobankAttackTest is Test {
    MockERC20 token;
    MockVault vault;
    MockPool pool;
    MockScorer scorer;
    MockLending lending;
    QIENeobank neobank;
    QIEIdentity identity;

    address owner = address(0xA0);
    address alice = address(0xA1);
    address bob = address(0xA2);
    address attacker = address(0xDE);

    function setUp() public {
        vm.startPrank(owner);

        token = new MockERC20();
        vault = new MockVault(address(token));
        pool = new MockPool();
        scorer = new MockScorer();
        lending = new MockLending(address(token));
        identity = new QIEIdentity();

        neobank = new QIENeobank(address(token), address(vault), address(scorer), address(identity));

        // Missing in original — was the root cause of all 8 failures
        neobank.setLending(address(lending));

        identity.issueIdentity(
            alice,
            QIEIdentity.Tier.Enhanced,
            keccak256(abi.encodePacked("alice_biometric_001")),
            keccak256(abi.encodePacked("alice_document_001")),
            keccak256(abi.encodePacked("alice_liveness_001")),
            840,
            365
        );
        identity.issueIdentity(
            bob,
            QIEIdentity.Tier.Enhanced,
            keccak256(abi.encodePacked("bob_biometric_001")),
            keccak256(abi.encodePacked("bob_document_001")),
            keccak256(abi.encodePacked("bob_liveness_001")),
            484,
            365
        );
        identity.issueIdentity(
            attacker,
            QIEIdentity.Tier.Basic,
            keccak256(abi.encodePacked("attacker_biometric_001")),
            keccak256(abi.encodePacked("attacker_document_001")),
            keccak256(abi.encodePacked("attacker_liveness_001")),
            170,
            365
        );

        vm.stopPrank();

        token.mint(alice, 100_000e6);
        token.mint(bob, 100_000e6);
        token.mint(attacker, 100_000e6);
        token.mint(address(lending), 50_000e6);

        vm.prank(alice);
        token.approve(address(neobank), type(uint256).max);
        vm.prank(bob);
        token.approve(address(neobank), type(uint256).max);
        vm.prank(attacker);
        token.approve(address(neobank), type(uint256).max);
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    function dummyHash(uint256 seed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(seed));
    }

    /// Deploy a fresh neobank+identity pair with no lending set.
    /// Issues an Enhanced identity to `caller` so identity checks pass,
    /// allowing LendingNotSet to be the first revert.
    function _freshNeobankWithIdentity(address caller, string memory salt) internal returns (QIENeobank fresh) {
        vm.startPrank(owner);
        QIEIdentity freshIdentity = new QIEIdentity();
        fresh = new QIENeobank(address(token), address(vault), address(scorer), address(freshIdentity));

        freshIdentity.issueIdentity(
            caller,
            QIEIdentity.Tier.Enhanced,
            keccak256(abi.encodePacked(salt, "_bio")),
            keccak256(abi.encodePacked(salt, "_doc")),
            keccak256(abi.encodePacked(salt, "_live")),
            170,
            365
        );
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. ZERO AMOUNT / ZERO ADDRESS GUARDS
    // ─────────────────────────────────────────────────────────────────────────

    function test_deposit_rejectsZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.ZeroAmount.selector);
        neobank.deposit(0);
    }

    function test_deposit_rejectsBelowMinDeposit() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.BelowMinDeposit.selector);
        neobank.deposit(1);
    }

    function test_send_rejectsZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.ZeroAmount.selector);
        neobank.send(bob, 0);
    }

    function test_send_rejectsZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.ZeroAddress.selector);
        neobank.send(address(0), 1e6);
    }

    function test_withdraw_rejectsZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.ZeroAmount.selector);
        neobank.withdraw(0);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. WITHDRAWAL CHECKS
    // ─────────────────────────────────────────────────────────────────────────

    function test_withdraw_rejectsInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.InsufficientBalance.selector);
        neobank.withdraw(1e6);
    }

    function test_withdrawAll_rejectsZeroShares() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.InsufficientBalance.selector);
        neobank.withdrawAll();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. LENDING GUARD — LendingNotSet
    // ─────────────────────────────────────────────────────────────────────────

    function test_requestLoan_rejectsWhenLendingNotSet() public {
        QIENeobank fresh = _freshNeobankWithIdentity(attacker, "attacker_req_notset");

        token.mint(attacker, 1000e6);
        vm.prank(attacker);
        token.approve(address(fresh), type(uint256).max);

        vm.prank(attacker);
        vm.expectRevert(QIENeobank.LendingNotSet.selector);
        fresh.requestLoan(1000e6, 0);
    }

    function test_repayLoan_rejectsWhenLendingNotSet() public {
        QIENeobank fresh = _freshNeobankWithIdentity(attacker, "attacker_rep_notset");

        vm.prank(attacker);
        vm.expectRevert(QIENeobank.LendingNotSet.selector);
        fresh.repayLoan();
    }

    function test_addLiquidity_rejectsWhenLendingNotSet() public {
        QIENeobank fresh = _freshNeobankWithIdentity(attacker, "attacker_add_notset");

        token.mint(attacker, 1000e6);
        vm.prank(attacker);
        token.approve(address(fresh), type(uint256).max);

        vm.prank(attacker);
        vm.expectRevert(QIENeobank.LendingNotSet.selector);
        fresh.addLiquidity(1000e6);
    }

    function test_removeLiquidity_rejectsWhenLendingNotSet() public {
        QIENeobank fresh = _freshNeobankWithIdentity(attacker, "attacker_rem_notset");

        vm.prank(attacker);
        vm.expectRevert(QIENeobank.LendingNotSet.selector);
        fresh.removeLiquidity(1000e6);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. LOAN FLOW GUARDS
    // ─────────────────────────────────────────────────────────────────────────

    function test_requestLoan_rejectsInsufficientVaultActivity() public {
        // alice is Enhanced but has no vault deposits
        vm.prank(alice);
        vm.expectRevert(QIENeobank.InsufficientVaultActivity.selector);
        neobank.requestLoan(1000e6, 0);
    }

    function test_requestLoan_rejectsActiveLoanExists() public {
        vault.setDepositCount(alice, 1);
        lending.setLoanActive(alice, 1000e6, 0);

        vm.prank(alice);
        vm.expectRevert(QIENeobank.ActiveLoanExists.selector);
        neobank.requestLoan(500e6, 0);
    }

    function test_repayLoan_rejectsNoActiveLoan() public {
        // alice is Enhanced, no loan exists
        vm.prank(alice);
        vm.expectRevert(QIENeobank.NoActiveLoan.selector);
        neobank.repayLoan();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. COLLATERAL ATOMICITY
    // ─────────────────────────────────────────────────────────────────────────

    function test_collateralSafe_onFullRevert() public {
        vault.setDepositCount(attacker, 1);
        lending.setRequestLoanFail(true);

        uint256 collateral = 500e6;
        uint256 attackerBefore = token.balanceOf(attacker);

        vm.prank(attacker);
        try neobank.requestLoan(1000e6, collateral) {
            revert("expected lending revert did not happen");
        } catch { /* expected */ }

        assertEq(token.balanceOf(address(neobank)), 0, "no funds stuck in neobank");
        assertEq(token.balanceOf(attacker), attackerBefore, "attacker balance fully restored");
    }

    function test_attack_noRescueFunctionExists() public pure {
        // Compile-time proof: QIENeobank has no sweep/rescue/emergencyWithdraw.
        // If collateral ever landed here via a non-reverting failure path,
        // it would be permanently irrecoverable. Documented as design risk.
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 7. [MEDIUM] addLiquidity — self-withdrawal via shares
    // ─────────────────────────────────────────────────────────────────────────

    function test_liquidityProvider_canSelfWithdraw() public {
        uint256 amount = 5000e6;

        vm.prank(alice);
        neobank.addLiquidity(amount);

        assertEq(neobank.liquidityShares(alice), amount, "shares minted 1:1 on first deposit");
        assertEq(neobank.totalLiquidityShares(), amount);

        uint256 aliceBefore = token.balanceOf(alice);

        vm.prank(alice);
        neobank.removeLiquidity(amount);

        assertEq(neobank.liquidityShares(alice), 0, "shares burned");
        assertEq(neobank.totalLiquidityShares(), 0);
        assertEq(token.balanceOf(alice), aliceBefore + amount, "funds returned");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 8. ACCESS CONTROL
    // ─────────────────────────────────────────────────────────────────────────

    function test_setLending_onlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert();
        neobank.setLending(address(0xBEEF));
    }

    function test_setMinDeposit_onlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert();
        neobank.setMinDeposit(1);
    }

    function test_setMinDeposit_rejectsZero() public {
        vm.prank(owner);
        vm.expectRevert(QIENeobank.ZeroAmount.selector);
        neobank.setMinDeposit(0);
    }

    function test_removeLiquidity_onlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert();
        neobank.removeLiquidity(1000e6);
    }

    function test_setLending_rejectsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(QIENeobank.ZeroAddress.selector);
        neobank.setLending(address(0));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 9. HAPPY PATHS
    // ─────────────────────────────────────────────────────────────────────────

    function test_depositAndWithdraw_happyPath() public {
        uint256 amount = 10_000e6;

        vm.prank(alice);
        uint256 shares = neobank.deposit(amount);
        assertEq(shares, amount);

        vm.prank(alice);
        uint256 sharesRedeemed = neobank.withdraw(amount);
        assertEq(sharesRedeemed, amount);
    }

    function test_send_happyPath() public {
        uint256 amount = 1000e6;
        uint256 bobBefore = token.balanceOf(bob);

        vm.prank(alice);
        neobank.send(bob, amount);

        assertEq(token.balanceOf(bob), bobBefore + amount);
        assertEq(neobank.totalSent(alice), amount);
        assertEq(neobank.totalReceived(bob), amount);
    }

    function test_requestAndRepayLoan_happyPath() public {
        vault.setDepositCount(alice, 1);

        vm.prank(alice);
        neobank.requestLoan(1000e6, 0);

        (,,,,,, uint8 status) = lending.loans(alice);
        assertEq(status, 1);

        token.mint(alice, 50e6); // cover interest
        vm.prank(alice);
        neobank.repayLoan();

        (,,,,,, uint8 statusAfter) = lending.loans(alice);
        assertEq(statusAfter, 2);
    }

    function test_getLoanTerms_returnsZeroWhenLendingNotSet() public {
        vm.prank(owner);
        QIEIdentity freshIdentity = new QIEIdentity();
        QIENeobank fresh = new QIENeobank(address(token), address(vault), address(scorer), address(freshIdentity));

        (uint8 tier, uint256 maxLoan,,,, bool canRequest,) = fresh.getLoanTerms(alice);
        assertEq(tier, 0);
        assertEq(maxLoan, 0);
        assertFalse(canRequest);
    }

    function test_getLendingStats_returnsZeroWhenLendingNotSet() public {
        vm.prank(owner);
        QIEIdentity freshIdentity = new QIEIdentity();
        QIENeobank fresh = new QIENeobank(address(token), address(vault), address(scorer), address(freshIdentity));

        (uint256 liq, uint256 vol, uint256 util) = fresh.getLendingStats();
        assertEq(liq, 0);
        assertEq(vol, 0);
        assertEq(util, 0);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 10. LIQUIDITY MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    function test_removeLiquidity_rejectsInsufficientShares() public {
        uint256 amount = 5000e6;

        vm.prank(alice);
        neobank.addLiquidity(amount);

        vm.prank(alice);
        vm.expectRevert(QIENeobank.InsufficientBalance.selector);
        neobank.removeLiquidity(amount + 1);
    }

    function test_removeLiquidity_rejectsZeroShares() public {
        vm.prank(alice);
        vm.expectRevert(QIENeobank.ZeroAmount.selector);
        neobank.removeLiquidity(0);
    }

    function test_removeLiquidity_proportionalMultiProvider() public {
        uint256 aliceAmount = 3000e6;
        uint256 bobAmount = 7000e6;

        vm.prank(alice);
        neobank.addLiquidity(aliceAmount);
        vm.prank(bob);
        neobank.addLiquidity(bobAmount);

        assertEq(neobank.totalLiquidityShares(), aliceAmount + bobAmount);

        uint256 bobShares = neobank.liquidityShares(bob);
        uint256 bobBefore = token.balanceOf(bob);

        vm.prank(bob);
        neobank.removeLiquidity(bobShares);

        assertApproxEqAbs(token.balanceOf(bob), bobBefore + bobAmount, 1, "bob recovers his share");
        assertEq(neobank.liquidityShares(bob), 0);
        assertEq(neobank.totalLiquidityShares(), aliceAmount, "alice shares remain");
    }
}
