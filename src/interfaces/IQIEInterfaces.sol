// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ── Vault Interface ───────────────────────────────────────
interface IQIEVault is IERC20 {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function receiveYield(uint256 amount) external;
    function receiveInterest(uint256 amount) external;

    // User tracking for credit scoring
    function totalDeposited(address user) external view returns (uint256);
    function depositCount(address user) external view returns (uint256);
    function firstDepositAt(address user) external view returns (uint256);

    // v2: passport-scoped aggregate stats (CreditScore falls back gracefully if absent)
    function getPassportStats(uint256 passportId)
        external
        view
        returns (
            uint256 firstDepositAt,
            uint256 totalDeposited,
            uint256 depositCount
        );

    // v2: per-wallet staled (age-filtered) stats for flash-deposit guard
    function staledDeposited(address user, uint256 minAge) external view returns (uint256);
    function staledDepositCount(address user, uint256 minAge) external view returns (uint256);
}

// ── Lending Interface ─────────────────────────────────────
interface IQIELending {
    enum LoanStatus {
        None,
        Active,
        Repaid,
        Defaulted,
        Liquidated
    }

    struct Loan {
        uint256 principal;
        uint256 collateral;
        uint256 interestRateBps;
        uint256 issuedAt;
        uint256 dueDate;
        uint256 repaid;
        LoanStatus status;
    }

    struct FeeConfig {
        uint256 originationFeeBps;
        uint256 protocolInterestShareBps;
        uint256 liquidationFeeBps;
        uint256 liquidatorIncentiveBps;
        uint256 lateFeeBps;
    }

    function loans(address borrower)
        external
        view
        returns (
            uint256 principal,
            uint256 collateral,
            uint256 interestRateBps,
            uint256 issuedAt,
            uint256 dueDate,
            uint256 repaid,
            uint8 status
        );
    function requestLoan(uint256 amount, uint256 collateral, address borrower, bool isUnsecured) external;
    function repayLoan(address borrower, uint256 amount) external;
    function getLoanTerms(address borrower)
        external
        view
        returns (uint8 tier, uint256 maxLoan, uint256 interestRateBps, uint256 requiredCollateral, uint256 currentScore);
    function getRepaymentAmount(address borrower)
        external
        view
        returns (uint256 totalDue, uint256 interestAccrued, uint256 lateFee);
    function addLiquidity(uint256 amount) external;
    function removeLiquidity(uint256 amount) external;
    function totalLiquidity() external view returns (uint256);
    function activeLoanVolume() external view returns (uint256);
    function feeConfig() external view returns (FeeConfig memory);
    function liquidate(address borrower) external;

    // Credit scoring data
    function onTimeRepayments(address user) external view returns (uint256);
    function lateRepayments(address user) external view returns (uint256);
    function totalRepayments(address user) external view returns (uint256);
    function defaultedLoans(address user) external view returns (uint256);
}

// ── Identity Interface ────────────────────────────────────
interface IQIEPass {
    function isVerified(address user) external view returns (bool);
    function getTier(address user) external view returns (uint8);
}

// ── Credit Score Interface ───────────────────────────────
interface ICreditScore {
    function getScore(address user) external view returns (uint256);
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
        );
    function getTier(address user) external view returns (string memory);
    function getScorePercent(address user) external view returns (uint256);
}

// ── Neobank Interface ─────────────────────────────────────
interface IQIENeobank {
    function deposit(uint256 amount) external returns (uint256 shares);
    function withdraw(uint256 assets) external returns (uint256 shares);
    function withdrawAll() external returns (uint256 assets);
    function send(address to, uint256 amount) external;
    function requestLoan(uint256 amount, uint256 collateral) external;
    function repayLoan() external;
    function addLiquidity(uint256 amount) external;
    function removeLiquidity(uint256 shares) external;
    function getAccount(address user)
        external
        view
        returns (
            bool hasIdentity,
            uint8 identityTier,
            uint256 balanceQUSDC,
            uint256 sharesHeld,
            uint256 totalDepositedLife,
            uint256 depositCountLife,
            uint256 firstDepositTime,
            uint256 score,
            uint256 scorePercent,
            string memory tier
        );
    function getLoanTerms(address user)
        external
        view
        returns (
            uint8 tier,
            uint256 maxLoan,
            uint256 interestRateBps,
            uint256 requiredCollateral,
            uint256 currentScore,
            bool canRequestLoan,
            uint256 maxUnsecuredLimit
        );
    function getLoanDetails(address user)
        external
        view
        returns (
            uint256 principal,
            uint256 collateral,
            uint256 interestRateBps,
            uint256 issuedAt,
            uint256 dueDate,
            uint256 repaid,
            uint8 status,
            uint256 totalDue,
            uint256 interestAccrued
        );
    function getLendingStats()
        external
        view
        returns (uint256 totalLiquidity, uint256 activeLoanVolume, uint256 utilizationRate);
    function getRepaymentHistory(address user)
        external
        view
        returns (uint256 onTime, uint256 late, uint256 total, uint256 defaulted, uint256 repaymentRate);
}