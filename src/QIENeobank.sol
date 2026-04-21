// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IQIEInterfaces.sol";
import "./QIEIdentity.sol";

contract QIENeobank is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();
    error BelowMinDeposit();
    error TransferFailed();
    error LendingNotSet();
    error NoActiveLoan();
    error ActiveLoanExists();
    error LoanRepaymentFailed();
    error InsufficientVaultActivity();
    error IdentityRequired();
    error TierTooLow();
    error LendingNotAllowed();
    error UnsecuredNotAllowed();
    error IdentityFrozen();
    error IdentityExpired();

    IERC20 public immutable qusdc;
    IQIEVault public immutable vault;
    ICreditScore public immutable scorer;
    QIEIdentity public immutable identity;
    IQIELending public lending;

    uint256 public minDeposit = 1e6;
    uint256 public minDepositsForLoan = 1;

    mapping(address => uint256) public totalSent;
    mapping(address => uint256) public totalReceived;
    mapping(address => uint256) public liquidityShares;
    uint256 public totalLiquidityShares;

    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event Sent(address indexed from, address indexed to, uint256 amount);
    event MinDepositUpdated(uint256 newMin);
    event LendingSet(address indexed lending);
    event LoanRequested(address indexed user, uint256 amount, uint256 collateral, uint8 tier, bool isUnsecured);
    event LoanRepaid(address indexed user, uint256 amount, uint256 interest);
    event LiquidityAdded(address indexed provider, uint256 amount, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amount, uint256 shares);

    constructor(address _qusdc, address _vault, address _scorer, address _identity) Ownable(msg.sender) {
        if (_qusdc == address(0) || _vault == address(0) || _scorer == address(0) || _identity == address(0)) {
            revert ZeroAddress();
        }
        qusdc = IERC20(_qusdc);
        vault = IQIEVault(_vault);
        scorer = ICreditScore(_scorer);
        identity = QIEIdentity(_identity);
    }

    modifier onlyVerified() {
        if (!identity.isVerified(msg.sender)) revert IdentityRequired();
        _;
    }

    modifier onlyTier(QIEIdentity.Tier minTier) {
        if (!identity.isVerifiedWithTier(msg.sender, minTier)) revert TierTooLow();
        _;
    }

    modifier onlyLendingAccess() {
        if (!identity.checkLendingAccess(msg.sender)) revert LendingNotAllowed();
        _;
    }

    modifier checkIdentityActive() {
        if (identity.isExpired(msg.sender)) revert IdentityExpired();
        if (identity.getTier(msg.sender) == QIEIdentity.Tier.None) revert IdentityFrozen();
        _;
    }

    function setMinDeposit(uint256 _min) external onlyOwner {
        if (_min == 0) revert ZeroAmount();
        minDeposit = _min;
        emit MinDepositUpdated(_min);
    }

    function setLending(address _lending) external onlyOwner {
        if (_lending == address(0)) revert ZeroAddress();
        lending = IQIELending(_lending);
        emit LendingSet(_lending);
    }

    function setMinDepositsForLoan(uint256 _min) external onlyOwner {
        minDepositsForLoan = _min;
    }

    function deposit(uint256 amount) external nonReentrant onlyVerified checkIdentityActive returns (uint256 shares) {
        if (amount == 0) revert ZeroAmount();
        QIEIdentity.Tier tier = identity.getTier(msg.sender);
        if (amount < identity.minDepositAmount(tier)) revert BelowMinDeposit();

        qusdc.safeTransferFrom(msg.sender, address(this), amount);
        qusdc.approve(address(vault), amount);
        shares = vault.deposit(amount, msg.sender);
        emit Deposited(msg.sender, amount, shares);
    }

    function withdraw(uint256 assets) external nonReentrant onlyVerified checkIdentityActive returns (uint256 shares) {
        if (assets == 0) revert ZeroAmount();
        if (assets > vault.maxWithdraw(msg.sender)) revert InsufficientBalance();
        shares = vault.withdraw(assets, msg.sender, msg.sender);
        emit Withdrawn(msg.sender, assets, shares);
    }

    function withdrawAll() external nonReentrant onlyVerified checkIdentityActive returns (uint256 assets) {
        uint256 shares = vault.maxRedeem(msg.sender);
        if (shares == 0) revert InsufficientBalance();
        assets = vault.redeem(shares, msg.sender, msg.sender);
        emit Withdrawn(msg.sender, assets, shares);
    }

    function send(address to, uint256 amount) external nonReentrant onlyVerified checkIdentityActive {
        if (amount == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();
        qusdc.safeTransferFrom(msg.sender, to, amount);
        totalSent[msg.sender] += amount;
        totalReceived[to] += amount;
        emit Sent(msg.sender, to, amount);
    }

    function requestLoan(uint256 amount, uint256 collateral)
        external
        nonReentrant
        onlyVerified
        onlyLendingAccess
        checkIdentityActive
    {
        if (address(lending) == address(0)) revert LendingNotSet();
        if (vault.depositCount(msg.sender) < minDepositsForLoan) revert InsufficientVaultActivity();

        (,,,,,, uint8 status) = lending.loans(msg.sender);
        if (status == uint8(IQIELending.LoanStatus.Active)) revert ActiveLoanExists();

        QIEIdentity.Tier tier = identity.getTier(msg.sender);
        uint256 maxUnsecured = identity.getMaxUnsecuredLimit(msg.sender);
        (uint8 loanTier,,,,) = lending.getLoanTerms(msg.sender);

        bool isUnsecured = (collateral == 0);

        if (isUnsecured) {
            if (amount > maxUnsecured) revert UnsecuredNotAllowed();
            if (tier < QIEIdentity.Tier.Enhanced) revert TierTooLow();
        }

        // FIX: Get origination fee from struct
        IQIELending.FeeConfig memory config = lending.feeConfig();
        uint256 originationFee = (amount * config.originationFeeBps) / 10000;

        uint256 totalFromUser = isUnsecured ? originationFee : collateral + originationFee;

        if (totalFromUser > 0) {
            qusdc.safeTransferFrom(msg.sender, address(this), totalFromUser);
            qusdc.forceApprove(address(lending), totalFromUser);
        }

        lending.requestLoan(amount, collateral, msg.sender, isUnsecured);

        emit LoanRequested(msg.sender, amount, collateral, loanTier, isUnsecured);
    }

    function repayLoan() external nonReentrant onlyVerified onlyLendingAccess checkIdentityActive {
        if (address(lending) == address(0)) revert LendingNotSet();
        (uint256 totalDue,,) = lending.getRepaymentAmount(msg.sender);
        if (totalDue == 0) revert NoActiveLoan();

        qusdc.safeTransferFrom(msg.sender, address(this), totalDue);
        qusdc.forceApprove(address(lending), totalDue);
        lending.repayLoan(msg.sender, totalDue);
        emit LoanRepaid(msg.sender, totalDue, 0);
    }

    function addLiquidity(uint256 amount) external nonReentrant onlyVerified onlyLendingAccess checkIdentityActive {
        if (address(lending) == address(0)) revert LendingNotSet();
        if (amount == 0) revert ZeroAmount();

        uint256 currentLiquidity = lending.totalLiquidity();
        uint256 sharesToMint = (totalLiquidityShares == 0 || currentLiquidity == 0)
            ? amount
            : (amount * totalLiquidityShares) / currentLiquidity;

        liquidityShares[msg.sender] += sharesToMint;
        totalLiquidityShares += sharesToMint;

        qusdc.safeTransferFrom(msg.sender, address(this), amount);
        qusdc.approve(address(lending), amount);
        lending.addLiquidity(amount);
        emit LiquidityAdded(msg.sender, amount, sharesToMint);
    }

    function removeLiquidity(uint256 shares) external nonReentrant onlyVerified onlyLendingAccess checkIdentityActive {
        if (address(lending) == address(0)) revert LendingNotSet();
        if (shares == 0) revert ZeroAmount();
        if (liquidityShares[msg.sender] < shares) revert InsufficientBalance();

        uint256 amount = (shares * lending.totalLiquidity()) / totalLiquidityShares;
        liquidityShares[msg.sender] -= shares;
        totalLiquidityShares -= shares;

        lending.removeLiquidity(amount);
        qusdc.safeTransfer(msg.sender, amount);
        emit LiquidityRemoved(msg.sender, amount, shares);
    }

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
        )
    {
        hasIdentity = identity.isVerified(user);
        identityTier = uint8(identity.getTier(user));
        balanceQUSDC = vault.maxWithdraw(user);
        sharesHeld = vault.balanceOf(user);
        totalDepositedLife = vault.totalDeposited(user);
        depositCountLife = vault.depositCount(user);
        firstDepositTime = vault.firstDepositAt(user);
        score = scorer.getScore(user);
        scorePercent = scorer.getScorePercent(user);
        tier = scorer.getTier(user);
    }

    function getIdentityAccountInfo(address user)
        external
        view
        returns (QIEIdentity.Tier tier, bool isActive, bool canLend, uint256 maxUnsecured, uint256 minDepositRequired)
    {
        tier = identity.getTier(user);
        isActive = tier != QIEIdentity.Tier.None && !identity.isExpired(user);
        canLend = identity.checkLendingAccess(user);
        maxUnsecured = identity.getMaxUnsecuredLimit(user);
        minDepositRequired = identity.minDepositAmount(tier);
    }

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
        return scorer.getScoreBreakdown(user);
    }

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
        )
    {
        if (address(lending) == address(0) || !identity.checkLendingAccess(user)) {
            return (0, 0, 0, 0, 0, false, 0);
        }
        (tier, maxLoan, interestRateBps, requiredCollateral, currentScore) = lending.getLoanTerms(user);

        (,,,,,, uint8 loanStatus) = lending.loans(user);
        bool noActiveLoan = loanStatus != uint8(IQIELending.LoanStatus.Active);
        bool hasActivity = vault.depositCount(user) >= minDepositsForLoan;
        canRequestLoan = noActiveLoan && hasActivity;

        maxUnsecuredLimit = identity.getMaxUnsecuredLimit(user);
    }

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
        )
    {
        if (address(lending) == address(0)) return (0, 0, 0, 0, 0, 0, 0, 0, 0);

        (principal, collateral, interestRateBps, issuedAt, dueDate, repaid, status) = lending.loans(user);

        (totalDue, interestAccrued,) = lending.getRepaymentAmount(user);
    }

    function getLendingStats()
        external
        view
        returns (uint256 totalLiquidity, uint256 activeLoanVolume, uint256 utilizationRate)
    {
        if (address(lending) == address(0)) return (0, 0, 0);
        totalLiquidity = lending.totalLiquidity();
        activeLoanVolume = lending.activeLoanVolume();
        utilizationRate = totalLiquidity > 0 ? (activeLoanVolume * 10000) / totalLiquidity : 0;
    }

    function getRepaymentHistory(address user)
        external
        view
        returns (uint256 onTime, uint256 late, uint256 total, uint256 defaulted, uint256 repaymentRate)
    {
        if (address(lending) == address(0)) return (0, 0, 0, 0, 0);
        onTime = lending.onTimeRepayments(user);
        late = lending.lateRepayments(user);
        total = lending.totalRepayments(user);
        defaulted = lending.defaultedLoans(user);
        repaymentRate = total == 0 ? 0 : (onTime * 100) / total;
    }
}
