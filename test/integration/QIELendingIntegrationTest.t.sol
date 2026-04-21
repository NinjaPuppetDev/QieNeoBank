// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/QIEVault.sol";
import "../../src/QIENeobank.sol";
import "../../src/CreditScore.sol";
import "../../src/QIELending.sol";
import "../../src/QIEIdentity.sol";
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

contract MockCreditScore is ICreditScore {
    mapping(address => uint256) private _scores;

    function setScore(address user, uint256 score) external {
        _scores[user] = score;
    }

    function getScore(address user) external view override returns (uint256) {
        return _scores[user];
    }

    function getTier(address) external pure override returns (string memory) {
        return "";
    }

    function getScorePercent(address) external pure override returns (uint256) {
        return 0;
    }

    function getScoreBreakdown(address user)
        external
        view
        override
        returns (uint256 total, uint256, uint256, uint256, uint256, uint256, string memory)
    {
        return (_scores[user], 0, 0, 0, 0, 0, "");
    }
}

contract QIELendingIntegrationTest is Test {
    MockQUSDC public qusdc;
    QIEVault public vault;
    MockCreditScore public scorer;
    QIEIdentity public identity;
    QIENeobank public neobank;
    QIELending public lending;

    address public owner = address(1);
    address public alice = address(3);
    address public bob = address(4);
    address public carol = address(5);
    address public liquidityProvider = address(6);

    uint256 constant INITIAL_BALANCE = 100_000e6;
    uint256 constant SCORE_BRONZE = 400;
    uint256 constant SCORE_SILVER = 600;
    uint256 constant SCORE_GOLD = 700;
    uint256 constant SCORE_PLATINUM = 800;
    uint256 constant ORIGINATION_FEE_BPS = 100;

    function setUp() public {
        vm.startPrank(owner);

        qusdc = new MockQUSDC();
        vault = new QIEVault(IERC20(address(qusdc)));
        scorer = new MockCreditScore();
        identity = new QIEIdentity();
        neobank = new QIENeobank(address(qusdc), address(vault), address(scorer), address(identity));

        lending = new QIELending(address(qusdc), address(vault), address(scorer), address(neobank), owner);
        neobank.setLending(address(lending));
        vault.setLendingContract(address(lending));

        qusdc.transfer(alice, INITIAL_BALANCE);
        qusdc.transfer(bob, INITIAL_BALANCE);
        qusdc.transfer(carol, INITIAL_BALANCE);
        qusdc.transfer(liquidityProvider, INITIAL_BALANCE * 10);

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
            QIEIdentity.Tier.Verified,
            keccak256("carol_bio"),
            keccak256("carol_doc"),
            keccak256("carol_live"),
            170,
            365
        );
        identity.issueIdentity(
            liquidityProvider,
            QIEIdentity.Tier.Enhanced,
            keccak256("lp_bio"),
            keccak256("lp_doc"),
            keccak256("lp_live"),
            484,
            365
        );

        vm.stopPrank();
    }

    function test_BronzeScore_SecuredLoan() public {
        _prepareForLoan(alice, SCORE_BRONZE);
        _addLiquidity(50_000e6);

        uint256 loanAmount = 1_000e6;
        uint256 collateral = 2_500e6;
        uint256 originationFee = (loanAmount * ORIGINATION_FEE_BPS) / 10000;
        uint256 totalNeeded = collateral + originationFee;

        vm.startPrank(alice);
        qusdc.approve(address(neobank), totalNeeded);
        neobank.requestLoan(loanAmount, collateral);
        vm.stopPrank();

        (
            uint256 principal,
            uint256 col,
            uint256 interestRate,
            uint256 issuedAt,
            uint256 dueDate,
            uint256 repaid,
            uint256 fee,
            QIELending.LoanStatus status
        ) = lending.loans(alice);
        assertTrue(status == QIELending.LoanStatus.Active);
        assertEq(principal, loanAmount - originationFee);
        assertEq(col, collateral);
    }

    function test_SilverScore_UnsecuredLoan() public {
        _prepareForLoan(alice, SCORE_SILVER);
        _addLiquidity(50_000e6);

        (,,,,, bool canRequest, uint256 maxUnsecured) = neobank.getLoanTerms(alice);

        assertTrue(canRequest);
        assertGt(maxUnsecured, 0);

        uint256 loanAmount = maxUnsecured > 0 && maxUnsecured < 5000e6 ? maxUnsecured : 3000e6;
        uint256 originationFee = (loanAmount * ORIGINATION_FEE_BPS) / 10000;

        vm.startPrank(alice);
        qusdc.approve(address(neobank), originationFee);
        neobank.requestLoan(loanAmount, 0);
        vm.stopPrank();

        (
            uint256 principal,
            uint256 col,
            uint256 interestRate,
            uint256 issuedAt,
            uint256 dueDate,
            uint256 repaid,
            uint256 fee,
            QIELending.LoanStatus status
        ) = lending.loans(alice);
        assertTrue(status == QIELending.LoanStatus.Active);
        assertEq(principal, loanAmount - originationFee);
    }

    function test_FullLoanRepayment() public {
        _prepareForLoan(alice, SCORE_BRONZE);
        _addLiquidity(50_000e6);

        uint256 loanAmount = 800e6;
        uint256 collateral = 2_000e6;
        uint256 originationFee = (loanAmount * ORIGINATION_FEE_BPS) / 10000;
        uint256 totalNeeded = collateral + originationFee;

        vm.startPrank(alice);
        qusdc.approve(address(neobank), totalNeeded);
        neobank.requestLoan(loanAmount, collateral);
        vm.stopPrank();

        vm.warp(block.timestamp + 30 days);

        (uint256 totalDue,,) = lending.getRepaymentAmount(alice);

        if (qusdc.balanceOf(alice) < totalDue) {
            vm.prank(owner);
            qusdc.mint(alice, totalDue - qusdc.balanceOf(alice) + 1e6);
        }

        _repayLoan(alice);

        (
            uint256 principal,
            uint256 col,
            uint256 interestRate,
            uint256 issuedAt,
            uint256 dueDate,
            uint256 repaid,
            uint256 fee,
            QIELending.LoanStatus status
        ) = lending.loans(alice);
        assertTrue(status == QIELending.LoanStatus.Repaid);
    }

    function test_Liquidate_AfterGracePeriod() public {
        _prepareForLoan(alice, SCORE_BRONZE);
        _addLiquidity(50_000e6);

        uint256 loanAmount = 800e6;
        uint256 collateral = 5_000e6;
        uint256 originationFee = (loanAmount * ORIGINATION_FEE_BPS) / 10000;
        uint256 totalNeeded = collateral + originationFee;

        vm.startPrank(alice);
        qusdc.approve(address(neobank), totalNeeded);
        neobank.requestLoan(loanAmount, collateral);
        vm.stopPrank();

        vm.warp(block.timestamp + 190 days);

        vm.prank(owner);
        lending.liquidate(alice);

        (
            uint256 principal,
            uint256 col,
            uint256 interestRate,
            uint256 issuedAt,
            uint256 dueDate,
            uint256 repaid,
            uint256 fee,
            QIELending.LoanStatus status
        ) = lending.loans(alice);
        assertTrue(status == QIELending.LoanStatus.Liquidated);
    }

    function _deposit(address user, uint256 amount) internal {
        vm.startPrank(user);
        qusdc.approve(address(neobank), amount);
        neobank.deposit(amount);
        vm.stopPrank();
    }

    function _addLiquidity(uint256 amount) internal {
        vm.startPrank(liquidityProvider);
        qusdc.approve(address(neobank), amount);
        neobank.addLiquidity(amount);
        vm.stopPrank();
    }

    function _setScore(address user, uint256 score) internal {
        scorer.setScore(user, score);
    }

    function _prepareForLoan(address user, uint256 score) internal {
        _deposit(user, 100e6);
        _setScore(user, score);
    }

    function _repayLoan(address user) internal {
        (uint256 totalDue,,) = lending.getRepaymentAmount(user);
        vm.startPrank(user);
        qusdc.approve(address(neobank), totalDue);
        neobank.repayLoan();
        vm.stopPrank();
    }
}
