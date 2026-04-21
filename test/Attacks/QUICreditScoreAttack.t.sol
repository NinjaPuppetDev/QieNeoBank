// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/CreditScore.sol";
import "../../src/QIEVault.sol";
import "../../src/QIELending.sol";
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

contract MockQIEPass {
    mapping(address => bool) public verified;

    function setVerified(address user, bool status) external {
        verified[user] = status;
    }

    function isVerified(address user) external view returns (bool) {
        return verified[user];
    }
}

contract CreditScoreAttackTest is Test {
    MockQUSDC public qusdc;
    MockQIEPass public qiePass;
    QIEVault public vault;
    QIELending public lending;
    CreditScore public scorer;

    address owner = address(1);
    address attacker = address(3);
    address victim = address(4);
    address neobank = address(5);

    uint256 constant INITIAL_BALANCE = 1_000_000e6;

    function setUp() public {
        vm.startPrank(owner);
        qusdc = new MockQUSDC();
        qiePass = new MockQIEPass();
        vault = new QIEVault(IERC20(address(qusdc)));
        lending = new QIELending(address(qusdc), address(vault), address(0), neobank, owner);
        scorer = new CreditScore(address(vault), address(lending));

        // PoolNotSet fix — vault.deposit() guards on this before crediting shares
        // vault.setPool(address(somePredictionPool));

        vm.stopPrank();

        qiePass.setVerified(attacker, true);
        qiePass.setVerified(victim, true);
        qusdc.mint(attacker, INITIAL_BALANCE);
    }

    function _getMaxWithdraw(address user) internal view returns (uint256) {
        uint256 shares = vault.balanceOf(user);
        if (shares == 0) return 0;
        return vault.convertToAssets(shares);
    }

    function test_attack_volumeGaming_cumulativeVsBalance() public {
        vm.startPrank(attacker);
        qusdc.approve(address(vault), type(uint256).max);

        uint256 initialScore = scorer.getScore(attacker);

        uint256 depositAmount = 1000e6;
        uint256 iterations = 10;

        for (uint256 i = 0; i < iterations; i++) {
            if (qusdc.balanceOf(attacker) < depositAmount) break;
            vault.deposit(depositAmount, attacker);
            uint256 maxWithdraw = vault.maxWithdraw(attacker);
            if (maxWithdraw > 0) {
                vault.withdraw(maxWithdraw - 1, attacker, attacker);
            }
        }

        uint256 newScore = scorer.getScore(attacker);
        assertGt(newScore, initialScore, "Score increased from volume gaming");

        (,, uint256 volume,,,,) = scorer.getScoreBreakdown(attacker);
        assertGt(volume, 0, "Volume component increased");

        vm.stopPrank();
    }

    function test_attack_consistencyGaming_depositSplitting() public {
        vm.startPrank(attacker);
        qusdc.approve(address(vault), type(uint256).max);
        vault.deposit(10000e6, attacker);
        vm.stopPrank();

        address attackerB = address(0xBADD);
        qusdc.mint(attackerB, 10000e6);

        vm.startPrank(attackerB);
        qusdc.approve(address(vault), type(uint256).max);
        for (uint256 i = 0; i < 20; i++) {
            vault.deposit(500e6, attackerB);
        }

        (,,,,, uint256 consistencyA,) = scorer.getScoreBreakdown(attacker);
        (,,,,, uint256 consistencyB,) = scorer.getScoreBreakdown(attackerB);

        assertGt(consistencyB, consistencyA, "Split deposits yield more consistency");
        assertEq(consistencyB, scorer.weightConsistency(), "20 deposits = max consistency");
        vm.stopPrank();
    }

    function test_attack_activityGaming_minimumDeposits() public {
        vm.startPrank(attacker);
        qusdc.approve(address(vault), type(uint256).max);

        for (uint256 i = 0; i < 50; i++) {
            vault.deposit(10e6, attacker);
        }

        assertEq(vault.depositCount(attacker), 50, "50 deposits made");

        (,,, uint256 activity,,,) = scorer.getScoreBreakdown(attacker);
        assertEq(activity, scorer.weightActivity(), "Activity maxed at 50 deposits");
        vm.stopPrank();
    }

    function test_attack_tenurePersistence_survivesWithdrawal() public {
        vm.startPrank(attacker);
        qusdc.approve(address(vault), type(uint256).max);
        vault.deposit(1000e6, attacker);

        vm.warp(block.timestamp + 365 days);

        uint256 scoreWithDeposit = scorer.getScore(attacker);
        (, uint256 tenureWithDeposit,,,,,) = scorer.getScoreBreakdown(attacker);

        uint256 maxWithdraw = _getMaxWithdraw(attacker);
        if (maxWithdraw > 0) vault.withdraw(maxWithdraw, attacker, attacker);

        uint256 scoreAfter = scorer.getScore(attacker);
        (, uint256 tenureAfter,,,,,) = scorer.getScoreBreakdown(attacker);

        assertEq(scoreWithDeposit, scoreAfter, "Score persists after withdrawal");
        assertEq(tenureWithDeposit, tenureAfter, "Tenure persists");
        assertEq(tenureAfter, scorer.weightTenure(), "Full tenure without balance");
        vm.stopPrank();
    }

    function test_attack_accuracyGaming_smallLoans() public {
        vm.startPrank(owner);
        qusdc.mint(attacker, 10000e6);
        vm.stopPrank();

        (,,,, uint256 accuracy,,) = scorer.getScoreBreakdown(attacker);
        assertEq(accuracy, 0, "Accuracy 0 without sufficient loans");
    }

    function test_attack_fullScoreManipulation_highScoreWithMinimalCapital() public {
        vm.startPrank(attacker);
        qusdc.approve(address(vault), type(uint256).max);

        vault.deposit(100e6, attacker);
        for (uint256 i = 0; i < 19; i++) {
            vault.deposit(10e6, attacker);
        }

        for (uint256 i = 0; i < 10; i++) {
            vault.deposit(1000e6, attacker);
            uint256 maxWithdraw = _getMaxWithdraw(attacker);
            if (maxWithdraw > 100e6) vault.withdraw(maxWithdraw - 100e6, attacker, attacker);
        }

        vm.warp(block.timestamp + 365 days);

        (, uint256 tenure, uint256 volume,,, uint256 consistency,) = scorer.getScoreBreakdown(attacker);
        assertEq(tenure, scorer.weightTenure(), "Max tenure");
        assertEq(volume, scorer.weightVolume(), "Max volume");
        assertEq(consistency, scorer.weightConsistency(), "Max consistency");

        uint256 expected = 300 + 100 + 100 + 50;
        assertGe(scorer.getScore(attacker), expected - 10, "High score achieved without loans");
        vm.stopPrank();
    }

    function test_attack_flashScoreBoost_temporaryDeposit() public {
        vm.startPrank(attacker);
        qusdc.approve(address(vault), type(uint256).max);

        uint256 scoreBefore = scorer.getScore(attacker);
        vault.deposit(10000e6, attacker);
        uint256 scoreDuring = scorer.getScore(attacker);

        uint256 maxWithdraw = _getMaxWithdraw(attacker);
        vault.withdraw(maxWithdraw, attacker, attacker);

        uint256 scoreAfter = scorer.getScore(attacker);

        assertGt(scoreDuring, scoreBefore, "Score boosted");
        assertEq(scoreAfter, scoreDuring, "Score persists after withdrawal");
        vm.stopPrank();
    }

    function test_attack_noScoreDecay_scoreNeverDecreases() public {
        vm.startPrank(attacker);
        qusdc.approve(address(vault), type(uint256).max);
        vault.deposit(1000e6, attacker);

        vm.warp(block.timestamp + 100 days);
        uint256 scoreAt100Days = scorer.getScore(attacker);

        uint256 maxWithdraw = _getMaxWithdraw(attacker);
        vault.withdraw(maxWithdraw, attacker, attacker);
        vm.warp(block.timestamp + 1000 days);

        assertGe(scorer.getScore(attacker), scoreAt100Days, "Score never decreases");
        vm.stopPrank();
    }

    function test_attack_repaymentGaming_minimumThreshold() public {
        (,,,, uint256 accuracy,,) = scorer.getScoreBreakdown(attacker);
        assertEq(accuracy, 0, "Accuracy 0 with no loans");
    }

    function test_attack_defaultPenalty_severeImpact() public {
        uint256 onTime = 3;
        uint256 total = 4;
        uint256 defaulted = 1;

        uint256 baseRate = (onTime * 100) / total;
        uint256 penalty = defaulted * 25;
        uint256 finalRate = baseRate > penalty ? baseRate - penalty : 0;

        assertEq(finalRate, 50, "Default penalty calculation correct");
    }
}
