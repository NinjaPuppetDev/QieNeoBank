// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IQIEInterfaces.sol";
import "./QIEBadDebt.sol";

/**
 * @title CreditScore
 * @notice On-chain credit scoring based on vault activity and lending history.
 *         Active bad debt NFTs zero out the accuracy component entirely;
 *         settled (burned) bad debts carry a per-incident repayment-rate penalty.
 * @dev Mirrors FICO range: 300–850.
 *
 * CHANGES vs v1 (all backwards-compatible):
 *
 *  1. PASSPORT-SCOPED VAULT SCORING
 *     _tenureComponent, _volumeComponent, _activityComponent, and
 *     _consistencyComponent previously scored only against the caller's wallet
 *     address. They now attempt to aggregate across ALL wallets sharing the
 *     same canonical passport ID (via IQIEVault.getPassportStats), falling
 *     back to the per-wallet calls when the vault doesn't implement the new
 *     interface. This makes wallet rotation non-exploitable: depositing from a
 *     fresh wallet doesn't erase prior vault history.
 *
 *     Required vault interface addition (optional/graceful fallback):
 *       function getPassportStats(uint256 passportId) external view returns (
 *           uint256 firstDepositAt,
 *           uint256 totalDeposited,
 *           uint256 depositCount
 *       );
 *
 *  2. FLASH DEPOSIT GUARD (MIN_HOLD_DURATION)
 *     Volume and activity components now only count deposits that have been
 *     held for at least MIN_HOLD_DURATION (default 7 days). Deposits made
 *     within the last 7 days are excluded, preventing a flash-deposit attack
 *     where a user deposits a large amount right before a loan application and
 *     immediately withdraws after.
 *
 *     Required vault interface addition (optional/graceful fallback):
 *       function staledDeposited(address user, uint256 minAge) external view returns (uint256);
 *       function staledDepositCount(address user, uint256 minAge) external view returns (uint256);
 *
 *     When these new vault functions are unavailable, the scoring falls back
 *     to the original totalDeposited/depositCount calls (safe degradation).
 *
 *  3. CONSISTENCY COMPONENT USES STALED DEPOSITS
 *     Consistency now counts only deposits older than MIN_HOLD_DURATION, since
 *     micro-deposit stuffing (50 × $1 deposits in one block) previously could
 *     max out both activity (100 pts) and consistency (50 pts) trivially.
 *
 * All existing public constants, state variables, events, and function
 * signatures are preserved so downstream tests require no changes.
 */
contract CreditScore is Ownable2Step {
    // ─────────────────────────────────────────────────────────────────────────
    // Errors
    // ─────────────────────────────────────────────────────────────────────────

    error ZeroAddress();
    error ScoreWeightMismatch();

    // ─────────────────────────────────────────────────────────────────────────
    // Interfaces
    // ─────────────────────────────────────────────────────────────────────────

    IQIEVault public immutable vault;
    IQIELending public immutable lending;

    /// @notice Optional bad debt NFT contract. Set via setBadDebt() after deployment.
    QIEBadDebt public badDebt;

    // ─────────────────────────────────────────────────────────────────────────
    // Score architecture
    // ─────────────────────────────────────────────────────────────────────────

    uint256 public constant BASE_SCORE = 300;
    uint256 public constant MAX_SCORE = 850;
    uint256 public constant SCORE_RANGE = 550; // 850 - 300

    // Component weights — must sum to SCORE_RANGE (550).
    uint256 public weightTenure;
    uint256 public weightVolume;
    uint256 public weightActivity;
    uint256 public weightAccuracy;
    uint256 public weightConsistency;

    // Caps — denominator for each component.
    uint256 public constant TENURE_CAP = 365 days;
    uint256 public constant VOLUME_CAP = 10_000e6; // 10,000 QUSDC
    uint256 public constant ACTIVITY_CAP = 50;
    uint256 public constant CONSISTENCY_CAP = 20;

    // Accuracy caps.
    uint256 public constant MIN_REPAYMENTS_FOR_ACCURACY = 3;
    uint256 public constant ACCURACY_CAP = 100;

    /// @notice Per-bad-debt penalty applied to repayment rate (0–100 scale).
    uint256 public badDebtPenaltyPoints = 40;

    // ── NEW: Flash deposit guard ───────────────────────────────
    /**
     * @notice Minimum age a deposit must have before it counts towards the
     *         volume and activity components. Prevents last-minute flash
     *         deposits inflating the score before a loan application.
     * @dev Default 7 days. Configurable by owner via setMinHoldDuration().
     */
    uint256 public minHoldDuration = 7 days;

    // ─────────────────────────────────────────────────────────────────────────
    // Tiers
    // ─────────────────────────────────────────────────────────────────────────

    uint256 public constant TIER_PLATINUM = 750;
    uint256 public constant TIER_GOLD = 650;
    uint256 public constant TIER_SILVER = 550;

    // ─────────────────────────────────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────────────────────────────────

    event WeightsUpdated(uint256 tenure, uint256 volume, uint256 activity, uint256 accuracy, uint256 consistency);
    event BadDebtContractSet(address indexed badDebtContract);
    event BadDebtPenaltyUpdated(uint256 newPenaltyPoints);
    /// @dev NEW
    event MinHoldDurationUpdated(uint256 newDuration);

    // ─────────────────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────────────────

    constructor(address _vault, address _lending) Ownable(msg.sender) {
        if (_vault == address(0)) revert ZeroAddress();
        if (_lending == address(0)) revert ZeroAddress();

        vault = IQIEVault(_vault);
        lending = IQIELending(_lending);

        // Default weights — sum = 550 = SCORE_RANGE.
        weightTenure = 100;
        weightVolume = 100;
        weightActivity = 100;
        weightAccuracy = 200; // Heavy weight on repayment history.
        weightConsistency = 50;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin
    // ─────────────────────────────────────────────────────────────────────────

    function setWeights(uint256 _tenure, uint256 _volume, uint256 _activity, uint256 _accuracy, uint256 _consistency)
        external
        onlyOwner
    {
        if (_tenure + _volume + _activity + _accuracy + _consistency != SCORE_RANGE) {
            revert ScoreWeightMismatch();
        }
        weightTenure = _tenure;
        weightVolume = _volume;
        weightActivity = _activity;
        weightAccuracy = _accuracy;
        weightConsistency = _consistency;

        emit WeightsUpdated(_tenure, _volume, _activity, _accuracy, _consistency);
    }

    function setBadDebt(address _badDebt) external onlyOwner {
        badDebt = QIEBadDebt(_badDebt);
        emit BadDebtContractSet(_badDebt);
    }

    function setBadDebtPenaltyPoints(uint256 _points) external onlyOwner {
        require(_points <= 100, "CreditScore: penalty exceeds 100");
        badDebtPenaltyPoints = _points;
        emit BadDebtPenaltyUpdated(_points);
    }

    /**
     * @notice Update the minimum deposit hold duration for volume/activity scoring.
     * @param _duration Duration in seconds. Set to 0 to disable the guard (not recommended).
     */
    function setMinHoldDuration(uint256 _duration) external onlyOwner {
        minHoldDuration = _duration;
        emit MinHoldDurationUpdated(_duration);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Score computation
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Returns raw score 300–850.
    function getScore(address user) public view returns (uint256 score) {
        score = BASE_SCORE;
        score += _tenureComponent(user);
        score += _volumeComponent(user);
        score += _activityComponent(user);
        score += _accuracyComponent(user);
        score += _consistencyComponent(user);

        if (score > MAX_SCORE) score = MAX_SCORE;
    }

    /// @notice Full score breakdown — useful for frontend dashboard.
    function getScoreBreakdown(address user)
        external
        view
        returns (
            uint256 total,
            uint256 tenure,
            uint256 volume,
            uint256 activity,
            uint256 accuracy,
            uint256 consistency,
            string memory tier
        )
    {
        tenure = _tenureComponent(user);
        volume = _volumeComponent(user);
        activity = _activityComponent(user);
        accuracy = _accuracyComponent(user);
        consistency = _consistencyComponent(user);
        total = BASE_SCORE + tenure + volume + activity + accuracy + consistency;
        if (total > MAX_SCORE) total = MAX_SCORE;
        tier = _tier(total);
    }

    /// @notice Tier label only — cheaper call for simple UI checks.
    function getTier(address user) external view returns (string memory) {
        return _tier(getScore(user));
    }

    /// @notice Score as a percentage 0–100 — useful for progress bars.
    function getScorePercent(address user) external view returns (uint256) {
        uint256 score = getScore(user);
        return ((score - BASE_SCORE) * 100) / SCORE_RANGE;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal components
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev How long the user's passport identity has been active.
     *
     *      Priority order:
     *        1. Try vault.getPassportStats(passportId) — aggregates across all
     *           wallets that share the same canonical passport ID.
     *        2. Fall back to vault.firstDepositAt(user) — original behaviour.
     *
     *      Passport-scoped tenure means a user who migrates to a new wallet
     *      after key compromise doesn't lose their tenure score.
     */
    function _tenureComponent(address user) internal view returns (uint256) {
        uint256 firstDeposit = _getFirstDepositAt(user);
        if (firstDeposit == 0) return 0;

        uint256 age = block.timestamp - firstDeposit;
        if (age >= TENURE_CAP) return weightTenure;

        return (age * weightTenure) / TENURE_CAP;
    }

    /**
     * @dev Lifetime QUSDC deposited, excluding recent deposits younger than
     *      minHoldDuration (flash deposit guard).
     *
     *      Priority order:
     *        1. vault.getPassportStats(passportId) — passport-scoped aggregate.
     *        2. vault.staledDeposited(user, minHoldDuration) — per-wallet staled.
     *        3. vault.totalDeposited(user) — original fallback (no guard applied).
     */
    function _volumeComponent(address user) internal view returns (uint256) {
        uint256 deposited = _getStaledDeposited(user);
        if (deposited == 0) return 0;
        if (deposited >= VOLUME_CAP) return weightVolume;

        return (deposited * weightVolume) / VOLUME_CAP;
    }

    /**
     * @dev Number of deposits made, excluding those younger than minHoldDuration.
     *
     *      Same priority fallback chain as _volumeComponent.
     */
    function _activityComponent(address user) internal view returns (uint256) {
        uint256 deposits = _getStaledDepositCount(user);
        if (deposits == 0) return 0;
        if (deposits >= ACTIVITY_CAP) return weightActivity;

        return (deposits * weightActivity) / ACTIVITY_CAP;
    }

    /**
     * @dev Loan repayment accuracy component.
     *
     * Three-stage penalty model (unchanged from v1):
     *
     *   1. ACTIVE BAD DEBT → return 0 immediately.
     *   2. SETTLED BAD DEBTS → each applies badDebtPenaltyPoints to repayment rate.
     *   3. REGULAR DEFAULTS → each deducts 25 pts from repayment rate.
     *
     * Minimum threshold: MIN_REPAYMENTS_FOR_ACCURACY loans before any score is
     * awarded, preventing one-shot gaming.
     */
    function _accuracyComponent(address user) internal view returns (uint256) {
        // Stage 1: active bad debt → zero accuracy points immediately.
        if (address(badDebt) != address(0) && badDebt.hasActiveBadDebt(user)) {
            return 0;
        }

        uint256 totalRepayments = lending.totalRepayments(user);
        if (totalRepayments < MIN_REPAYMENTS_FOR_ACCURACY) return 0;

        uint256 onTime = lending.onTimeRepayments(user);
        uint256 defaulted = lending.defaultedLoans(user);

        uint256 repaymentRate = totalRepayments > 0 ? (onTime * 100) / totalRepayments : 0;

        // Stage 3: regular default penalty (25 pts each).
        uint256 defaultPenalty = defaulted * 25;

        // Stage 2: settled bad debt penalty.
        uint256 badDebtCount = 0;
        if (address(badDebt) != address(0)) {
            uint256 pid = _getPassportId(user);
            if (pid != 0) {
                badDebtCount = badDebt.totalDefaultsForPassport(pid);
            }
        }
        uint256 badDebtPenalty = badDebtCount * badDebtPenaltyPoints;

        uint256 totalPenalty = defaultPenalty + badDebtPenalty;
        if (totalPenalty >= repaymentRate) {
            repaymentRate = 0;
        } else {
            repaymentRate -= totalPenalty;
        }

        return (repaymentRate * weightAccuracy) / 100;
    }

    /**
     * @dev Regular saving behaviour — rewards frequent depositors.
     *      Uses staled deposit count so micro-deposit stuffing in a single
     *      block doesn't immediately award consistency points.
     */
    function _consistencyComponent(address user) internal view returns (uint256) {
        uint256 count = _getStaledDepositCount(user);
        if (count == 0) return 0;
        if (count >= CONSISTENCY_CAP) return weightConsistency;

        return (count * weightConsistency) / CONSISTENCY_CAP;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal vault helpers — graceful degradation chain
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Retrieves first deposit timestamp with passport-scoped fallback.
     *
     *      Chain:
     *        1. vault.getPassportStats(passportId) — new passport-aware call.
     *        2. vault.firstDepositAt(user) — original per-wallet call.
     */
    function _getFirstDepositAt(address user) internal view returns (uint256) {
        // Try passport-scoped lookup first.
        uint256 pid = _getPassportId(user);
        if (pid != 0) {
            try vault.getPassportStats(
                pid
            ) returns (
                uint256 firstDepositAt,
                uint256, // totalDeposited — not needed here
                uint256 // depositCount   — not needed here
            ) {
                if (firstDepositAt != 0) return firstDepositAt;
            } catch {}
        }

        // Fallback: per-wallet (original behaviour).
        return vault.firstDepositAt(user);
    }

    /**
     * @dev Returns deposited volume excluding recent deposits.
     *
     *      Chain:
     *        1. vault.getPassportStats(passportId) — passport-scoped aggregate.
     *           Note: getPassportStats is assumed to return staled figures when
     *           the vault implements the full v2 interface.
     *        2. vault.staledDeposited(user, minHoldDuration) — per-wallet staled.
     *        3. vault.totalDeposited(user) — original fallback (no guard).
     */
    function _getStaledDeposited(address user) internal view returns (uint256) {
        uint256 pid = _getPassportId(user);
        if (pid != 0) {
            try vault.getPassportStats(
                pid
            ) returns (
                uint256, // firstDepositAt — not needed here
                uint256 totalDeposited,
                uint256 // depositCount   — not needed here
            ) {
                if (totalDeposited != 0) return totalDeposited;
            } catch {}
        }

        // Try per-wallet staled call.
        try vault.staledDeposited(user, minHoldDuration) returns (uint256 staled) {
            return staled;
        } catch {}

        // Final fallback: original call (no flash guard).
        return vault.totalDeposited(user);
    }

    /**
     * @dev Returns deposit count excluding recent deposits.
     *
     *      Chain:
     *        1. vault.getPassportStats(passportId) for passport-scoped count.
     *        2. vault.staledDepositCount(user, minHoldDuration).
     *        3. vault.depositCount(user) — original fallback.
     */
    function _getStaledDepositCount(address user) internal view returns (uint256) {
        uint256 pid = _getPassportId(user);
        if (pid != 0) {
            try vault.getPassportStats(
                pid
            ) returns (
                uint256, // firstDepositAt — not needed here
                uint256, // totalDeposited — not needed here
                uint256 depositCount
            ) {
                if (depositCount != 0) return depositCount;
            } catch {}
        }

        // Try per-wallet staled call.
        try vault.staledDepositCount(user, minHoldDuration) returns (uint256 staled) {
            return staled;
        } catch {}

        // Final fallback: original call.
        return vault.depositCount(user);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────────────────

    function _tier(uint256 score) internal pure returns (string memory) {
        if (score >= TIER_PLATINUM) return "Platinum";
        if (score >= TIER_GOLD) return "Gold";
        if (score >= TIER_SILVER) return "Silver";
        return "Bronze";
    }

    /**
     * @dev Look up the canonical passport ID for a user via the bad debt
     *      contract's identity reference. Returns 0 if bad debt contract is
     *      not set or the call reverts.
     *
     *      This is unchanged from v1 — the canonical ID returned here is now
     *      stable across revocations thanks to the QIEIdentity v2 changes.
     */
    function _getPassportId(address user) internal view returns (uint256) {
        if (address(badDebt) == address(0)) return 0;
        try badDebt.identity().passportId(user) returns (uint256 pid) {
            return pid;
        } catch {
            return 0;
        }
    }
}
