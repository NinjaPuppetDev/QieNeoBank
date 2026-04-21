// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/QIEVault.sol";
import "../../src/QIENeobank.sol";
import "../../src/CreditScore.sol";
import "../../src/QIELending.sol";
import "../../src/QIEIdentity.sol";
import "../../src/QIEBadDebt.sol";
import "../../src/interfaces/IQIEInterfaces.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockQUSDC is ERC20 {
    constructor() ERC20("QIE USD Coin", "QUSDC") {
        _mint(msg.sender, 1_000_000_000e6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract QIEIntegrationTest is Test {
    MockQUSDC public qusdc;
    QIEVault public vault;
    CreditScore public scorer;
    QIEIdentity public identity;
    QIENeobank public neobank;
    QIELending public lending;
    QIEBadDebt public badDebtNFT;

    address public owner = address(1);
    address public alice = address(3);
    address public bob = address(4);
    address public carol = address(5);

    uint256 constant INITIAL_BALANCE = 100_000e6;
    uint256 constant ORIGINATION_FEE_BPS = 100;

    function setUp() public {
        vm.startPrank(owner);

        qusdc = new MockQUSDC();
        vault = new QIEVault(IERC20(address(qusdc)));
        identity = new QIEIdentity();

        lending = new QIELending(address(qusdc), address(vault), address(0), address(0), owner);
        scorer = new CreditScore(address(vault), address(lending));
        neobank = new QIENeobank(address(qusdc), address(vault), address(scorer), address(identity));

        lending.setNeobank(address(neobank));
        lending.setCreditScore(address(scorer));
        neobank.setLending(address(lending));
        vault.setLendingContract(address(lending));

        // ── Bad debt wiring ──────────────────────────────────────────────────
        badDebtNFT = new QIEBadDebt(address(identity));
        lending.setBadDebt(address(badDebtNFT));
        badDebtNFT.authorizeMinter(address(lending), true);
        scorer.setBadDebt(address(badDebtNFT));
        // ─────────────────────────────────────────────────────────────────────

        qusdc.transfer(alice, INITIAL_BALANCE);
        qusdc.transfer(bob, INITIAL_BALANCE);
        qusdc.transfer(carol, INITIAL_BALANCE);

        // Enhanced tier → 5_000 USDC unsecured ceiling, fits loanAmount = 2_000e6
        // in test_BadDebtFullFlow. Verified ceiling (500 USDC) was too low.
        identity.issueIdentity(
            alice,
            QIEIdentity.Tier.Enhanced,
            keccak256("alice_bio"),
            keccak256("alice_doc"),
            keccak256("alice_live"),
            840,
            365
        );
        identity.issueIdentity(
            bob, QIEIdentity.Tier.Enhanced, keccak256("bob_bio"), keccak256("bob_doc"), keccak256("bob_live"), 484, 365
        );
        identity.issueIdentity(
            carol,
            QIEIdentity.Tier.Basic,
            keccak256("carol_bio"),
            keccak256("carol_doc"),
            keccak256("carol_live"),
            170,
            365
        );

        vm.stopPrank();
    }

    // ── Existing tests (unchanged) ────────────────────────────────────────────

    function test_LendingFlow() public {
        vm.startPrank(bob);
        qusdc.approve(address(neobank), 50_000e6);
        neobank.addLiquidity(50_000e6);

        qusdc.approve(address(neobank), 10_000e6);
        neobank.deposit(10_000e6);

        uint256 loanAmount = 500e6;
        uint256 collateral = loanAmount * 2;
        uint256 originationFee = (loanAmount * ORIGINATION_FEE_BPS) / 10000;
        uint256 totalNeeded = collateral + originationFee;

        qusdc.approve(address(neobank), totalNeeded);
        neobank.requestLoan(loanAmount, collateral);

        (uint256 principal,,,,,,,) = lending.loans(bob);
        assertEq(principal, loanAmount - originationFee);
        vm.stopPrank();
    }

    function test_RepaymentFlow() public {
        vm.startPrank(bob);
        qusdc.approve(address(neobank), 50_000e6);
        neobank.addLiquidity(50_000e6);

        qusdc.approve(address(neobank), 10_000e6);
        neobank.deposit(10_000e6);

        uint256 loanAmount = 500e6;
        uint256 collateral = loanAmount * 2;
        uint256 originationFee = (loanAmount * ORIGINATION_FEE_BPS) / 10000;
        uint256 totalNeeded = collateral + originationFee;

        qusdc.approve(address(neobank), totalNeeded);
        neobank.requestLoan(loanAmount, collateral);
        vm.stopPrank();

        vm.warp(block.timestamp + 30 days);

        (uint256 totalDue,,) = lending.getRepaymentAmount(bob);

        if (qusdc.balanceOf(bob) < totalDue) {
            vm.prank(owner);
            qusdc.mint(bob, totalDue - qusdc.balanceOf(bob) + 1e6);
        }

        vm.startPrank(bob);
        qusdc.approve(address(neobank), totalDue);
        neobank.repayLoan();
        vm.stopPrank();

        (,,,,,,, QIELending.LoanStatus status) = lending.loans(bob);
        assertTrue(status == QIELending.LoanStatus.Repaid);
    }

    // ── Bad debt integration test ─────────────────────────────────────────────

    /**
     * @notice Full E2E bad debt lifecycle:
     *   alice (Silver/Verified) takes an unsecured loan → defaults → bad debt
     *   declared → debt buyer settles → NFT burned → proceeds distributed.
     */
    function test_BadDebtFullFlow() public {
        // ── Setup liquidity ──────────────────────────────────────────────────
        vm.startPrank(bob);
        qusdc.approve(address(neobank), 50_000e6);
        neobank.addLiquidity(50_000e6);
        vm.stopPrank();

        // ── Build alice's credit profile ─────────────────────────────────────
        // Target score ≥ 550 (Silver) to unlock unsecured loans.
        // Strategy: 20 deposits totalling 10_000 USDC + 365-day tenure warp.
        //
        // Score math:
        //   BASE        = 300
        //   tenure      = 100  (365 days elapsed since first deposit)
        //   volume      = 100  (10_000 USDC == VOLUME_CAP)
        //   activity    =  40  (20 deposits / 50 cap * 100)
        //   accuracy    =   0  (< 3 repayments — threshold not met)
        //   consistency =  50  (20 deposits >= CONSISTENCY_CAP of 20)
        //   TOTAL       = 590  ✓ Silver
        uint256 depositPerRound = 500e6; // 20 × 500 = 10_000 USDC == VOLUME_CAP
        uint256 numDeposits = 20;

        vm.startPrank(alice);
        // First deposit establishes firstDepositAt timestamp.
        qusdc.approve(address(neobank), depositPerRound * numDeposits);
        for (uint256 i = 0; i < numDeposits; i++) {
            neobank.deposit(depositPerRound);
        }
        vm.stopPrank();

        // Warp AFTER first deposit so tenure accrues.
        vm.warp(block.timestamp + 365 days);

        // ── alice takes unsecured loan ────────────────────────────────────────
        uint256 loanAmount = 2_000e6;
        uint256 originationFee = (loanAmount * ORIGINATION_FEE_BPS) / 10000;

        vm.startPrank(alice);
        qusdc.approve(address(neobank), originationFee);
        neobank.requestLoan(loanAmount, 0);
        vm.stopPrank();

        assertTrue(lending.isUnsecuredLoan(alice), "should be unsecured");
        (,,,,,,, QIELending.LoanStatus statusBefore) = lending.loans(alice);
        assertTrue(statusBefore == QIELending.LoanStatus.Active);

        // ── Warp past tenure + grace period ──────────────────────────────────
        // Silver tier: 12 months tenure + 7 days grace.
        // We already warped 365 days; warp another 370 to blow past due date.
        vm.warp(block.timestamp + 370 days);

        assertTrue(lending.isEligibleForBadDebt(alice), "alice should be eligible");

        // ── Declare bad debt ──────────────────────────────────────────────────
        vm.prank(owner);
        lending.declareBadDebt(alice);

        (,,,,,,, QIELending.LoanStatus statusAfter) = lending.loans(alice);
        assertTrue(statusAfter == QIELending.LoanStatus.BadDebt, "status should be BadDebt");

        uint256 tokenId = lending.activeBadDebtToken(alice);
        assertGt(tokenId, 0, "bad debt token should be minted");

        assertEq(badDebtNFT.ownerOf(tokenId), alice);
        assertTrue(badDebtNFT.hasActiveBadDebt(alice));
        assertEq(badDebtNFT.totalDefaultsForPassport(identity.passportId(alice)), 1);

        // ── Settle: debt buyer pays 60% of principal lost ─────────────────────
        (, uint256 principalLost,,,,,,) = badDebtNFT.records(tokenId);
        uint256 recovered = (principalLost * 60) / 100;

        vm.prank(owner);
        qusdc.mint(address(neobank), recovered);

        uint256 vaultBalanceBefore = qusdc.balanceOf(address(vault));
        uint256 treasuryBalanceBefore = qusdc.balanceOf(owner);

        vm.startPrank(address(neobank));
        qusdc.approve(address(lending), recovered);
        lending.settleBadDebt(alice, recovered);
        vm.stopPrank();

        // NFT burned
        assertEq(lending.activeBadDebtToken(alice), 0, "activeBadDebtToken should clear");
        assertFalse(badDebtNFT.hasActiveBadDebt(alice), "NFT should be burned");

        uint256 expectedProtocol = (recovered * 2000) / 10000;
        assertEq(qusdc.balanceOf(owner) - treasuryBalanceBefore, expectedProtocol, "protocol share");
        assertGe(qusdc.balanceOf(address(vault)), vaultBalanceBefore, "vault share");

        // Historical record persists after burn
        assertEq(badDebtNFT.totalDefaultsForPassport(identity.passportId(alice)), 1);
    }
}
