// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IQIEInterfaces.sol";
import "./QIEBadDebt.sol";

/**
 * @title QIELending
 * @notice Lending protocol with tiered collateral requirements and health factor monitoring.
 *         Unsecured loan defaults are tokenized as resaleable bad debt NFTs via QIEBadDebt.
 * @dev Supports both collateralized and unsecured loans based on credit tier.
 *      Bad debt flow: declareBadDebt() → NFT minted to borrower → buyer acquires NFT →
 *      settleBadDebt() burns NFT and distributes recovery proceeds.
 */
contract QIELending is Ownable2Step, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ─────────────────────────────────────────────────────────────────────────
    // Errors
    // ─────────────────────────────────────────────────────────────────────────

    error InsufficientCreditScore(uint256 score, uint256 minRequired);
    error LoanCapExceeded(uint256 requested, uint256 maxAllowed);
    error InsufficientCollateral(uint256 provided, uint256 required);
    error ActiveLoanExists(address borrower);
    error LoanNotFound(address borrower);
    error LoanNotDue(uint256 dueDate);
    error DefaultTooEarly(uint256 canDefaultAfter);
    error PaymentBelowMinimum(uint256 sent, uint256 minimum);
    error ZeroAddress();
    error ZeroAmount();
    error NotNeobank();
    error NotLiquidator();
    error NoCollateralToLiquidate();
    error InvalidFeeConfig();
    error UnsecuredNotAllowed();
    error HealthFactorTooLow(uint256 healthFactor, uint256 minHealthFactor);
    error CollateralNotRequired();
    // Bad debt errors
    error BadDebtNotConfigured();
    error NotEligibleForBadDebt(address borrower);
    error BadDebtAlreadyDeclared(address borrower);
    error BadDebtNotActive(address borrower);

    // ─────────────────────────────────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────────────────────────────────

    IERC20 public immutable qusdc;
    IQIEVault public immutable vault;
    IQIENeobank public neobank;
    address public protocolTreasury;
    ICreditScore public scorer;

    /// @notice Optional bad debt NFT contract. Set via setBadDebt() after deployment.
    QIEBadDebt public badDebt;

    struct FeeConfig {
        uint256 originationFeeBps;
        uint256 protocolInterestShareBps;
        uint256 liquidationFeeBps;
        uint256 liquidatorIncentiveBps;
        uint256 lateFeeBps;
    }

    FeeConfig public feeConfig;

    uint256 public totalOriginationFees;
    uint256 public totalInterestFees;
    uint256 public totalLiquidationFees;
    uint256 public totalLateFees;

    // NOTE: Loan struct maintains 8 fields for backward compatibility with tests.
    struct Loan {
        uint256 principal;
        uint256 collateral;
        uint256 interestRateBps;
        uint256 issuedAt;
        uint256 dueDate;
        uint256 repaid;
        uint256 originationFee;
        LoanStatus status;
    }

    enum LoanStatus {
        None,
        Active,
        Repaid,
        Defaulted,
        Liquidated,
        BadDebt // Unsecured default tokenized as resaleable NFT
    }

    struct TierConfig {
        uint256 minScore;
        uint256 maxLoan;
        uint256 ltvBps;
        uint256 liquidationThresholdBps;
        uint256 interestRateBps;
        uint256 tenureMonths;
        uint256 gracePeriodDays;
        bool allowsUnsecured;
    }

    mapping(uint8 => TierConfig) public tiers;
    mapping(address => Loan) public loans;
    mapping(address => bool) public authorizedLiquidators;
    mapping(address => bool) public isUnsecuredLoan;

    /// @notice Active bad debt NFT token ID per borrower (0 = none).
    mapping(address => uint256) public activeBadDebtToken;

    uint256 public totalLiquidity;
    uint256 public activeLoanVolume;
    uint256 public constant LIQUIDITY_RESERVE_BPS = 2000;

    uint256 public constant MIN_HEALTH_FACTOR = 1.25e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 1.0e18;

    // ─────────────────────────────────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────────────────────────────────

    event LoanRequested(
        address indexed borrower,
        uint256 principal,
        uint256 originationFee,
        uint256 collateral,
        uint8 tier,
        uint256 interestRate,
        bool isUnsecured
    );
    event LoanRepaid(
        address indexed borrower, uint256 principalRepaid, uint256 interestPaid, uint256 protocolFee, uint256 lpYield
    );
    event LoanDefaulted(address indexed borrower, uint256 lossAmount);
    event LoanLiquidated(
        address indexed borrower,
        address indexed liquidator,
        uint256 collateralSeized,
        uint256 protocolFee,
        uint256 liquidatorBonus,
        uint256 borrowerRefund
    );
    event LateFeeApplied(address indexed borrower, uint256 lateFee);
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event FeeConfigUpdated(FeeConfig newConfig);
    event TreasuryUpdated(address newTreasury);
    event CreditScoreUpdated(address newScorer);
    event LiquidatorAuthorized(address liquidator, bool authorized);
    event HealthFactorUpdated(address indexed borrower, uint256 healthFactor);
    /// @notice Emitted when an unsecured overdue loan is tokenized as a bad debt NFT.
    event BadDebtDeclared(
        address indexed borrower,
        uint256 indexed badDebtTokenId,
        uint256 principalLost,
        uint256 interestLost,
        uint256 lateFeesLost,
        uint8 tierAtDefault
    );
    /// @notice Emitted when a bad debt NFT is settled (burned) after recovery payment.
    event BadDebtSettled(
        address indexed borrower,
        uint256 indexed badDebtTokenId,
        uint256 recovered,
        uint256 protocolShare,
        uint256 vaultShare
    );
    event BadDebtContractSet(address indexed badDebtContract);

    // ─────────────────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────────────────

    constructor(address _qusdc, address _vault, address _scorer, address _neobank, address _treasury)
        Ownable(msg.sender)
    {
        if (_qusdc == address(0)) revert ZeroAddress();
        if (_vault == address(0)) revert ZeroAddress();
        if (_treasury == address(0)) revert ZeroAddress();

        qusdc = IERC20(_qusdc);
        vault = IQIEVault(_vault);
        scorer = ICreditScore(_scorer);
        neobank = IQIENeobank(_neobank);
        protocolTreasury = _treasury;

        feeConfig = FeeConfig(100, 2000, 500, 200, 500);

        // Tier 0: Bronze — collateralized only, 50% LTV
        tiers[0] = TierConfig({
            minScore: 300,
            maxLoan: 1_000e6,
            ltvBps: 5000,
            liquidationThresholdBps: 8000,
            interestRateBps: 2500,
            tenureMonths: 6,
            gracePeriodDays: 7,
            allowsUnsecured: false
        });

        // Tier 1: Silver — allows unsecured
        tiers[1] = TierConfig({
            minScore: 550,
            maxLoan: 5_000e6,
            ltvBps: 5000,
            liquidationThresholdBps: 8000,
            interestRateBps: 1800,
            tenureMonths: 12,
            gracePeriodDays: 7,
            allowsUnsecured: true
        });

        // Tier 2: Gold — allows unsecured, 75% LTV
        tiers[2] = TierConfig({
            minScore: 650,
            maxLoan: 20_000e6,
            ltvBps: 7500,
            liquidationThresholdBps: 8500,
            interestRateBps: 1200,
            tenureMonths: 18,
            gracePeriodDays: 14,
            allowsUnsecured: true
        });

        // Tier 3: Platinum — allows unsecured, 100% LTV
        tiers[3] = TierConfig({
            minScore: 750,
            maxLoan: 50_000e6,
            ltvBps: 10000,
            liquidationThresholdBps: 9000,
            interestRateBps: 800,
            tenureMonths: 24,
            gracePeriodDays: 14,
            allowsUnsecured: true
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin
    // ─────────────────────────────────────────────────────────────────────────

    function setNeobank(address _neobank) external onlyOwner {
        if (_neobank == address(0)) revert ZeroAddress();
        neobank = IQIENeobank(_neobank);
    }

    function setCreditScore(address _scorer) external onlyOwner {
        if (_scorer == address(0)) revert ZeroAddress();
        scorer = ICreditScore(_scorer);
        emit CreditScoreUpdated(_scorer);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        protocolTreasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setFeeConfig(FeeConfig calldata _config) external onlyOwner {
        if (_config.originationFeeBps > 1000) revert InvalidFeeConfig();
        if (_config.protocolInterestShareBps > 5000) revert InvalidFeeConfig();
        if (_config.liquidationFeeBps + _config.liquidatorIncentiveBps > 3000) revert InvalidFeeConfig();
        if (_config.lateFeeBps > 1000) revert InvalidFeeConfig();
        feeConfig = _config;
        emit FeeConfigUpdated(_config);
    }

    function authorizeLiquidator(address liquidator, bool authorized) external onlyOwner {
        authorizedLiquidators[liquidator] = authorized;
        emit LiquidatorAuthorized(liquidator, authorized);
    }

    /**
     * @notice Set the bad debt NFT contract. QIELending must be an authorized minter
     *         on QIEBadDebt before declareBadDebt() can be called.
     * @param _badDebt Address of the deployed QIEBadDebt contract (zero to disable).
     */
    function setBadDebt(address _badDebt) external onlyOwner {
        badDebt = QIEBadDebt(_badDebt);
        emit BadDebtContractSet(_badDebt);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Modifiers
    // ─────────────────────────────────────────────────────────────────────────

    modifier onlyNeobank() {
        if (msg.sender != address(neobank)) revert NotNeobank();
        _;
    }

    modifier onlyLiquidator() {
        if (!authorizedLiquidators[msg.sender] && msg.sender != owner()) revert NotLiquidator();
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // View helpers
    // ─────────────────────────────────────────────────────────────────────────

    function getHealthFactor(address borrower) public view returns (uint256 healthFactor) {
        Loan memory loan = loans[borrower];
        if (loan.status != LoanStatus.Active) return type(uint256).max;
        if (isUnsecuredLoan[borrower] || loan.collateral == 0) return type(uint256).max;

        (uint256 totalDue,,) = getRepaymentAmount(borrower);
        if (totalDue == 0) return type(uint256).max;

        return (loan.collateral * 1e18) / totalDue;
    }

    function isLiquidatable(address borrower) public view returns (bool) {
        Loan memory loan = loans[borrower];
        if (loan.status != LoanStatus.Active) return false;

        TierConfig memory config = tiers[_getTier(scorer.getScore(borrower))];
        bool pastGrace = block.timestamp > loan.dueDate + (config.gracePeriodDays * 1 days);

        bool underCollateralized = false;
        if (!isUnsecuredLoan[borrower] && loan.collateral > 0) {
            uint256 healthFactor = getHealthFactor(borrower);
            underCollateralized = healthFactor < LIQUIDATION_THRESHOLD;
        }

        return pastGrace || underCollateralized;
    }

    /**
     * @notice Whether an unsecured active loan is eligible to be declared bad debt.
     * @dev Eligible when past the grace period and bad debt contract is configured.
     */
    function isEligibleForBadDebt(address borrower) public view returns (bool) {
        Loan memory loan = loans[borrower];
        if (loan.status != LoanStatus.Active) return false;
        if (!isUnsecuredLoan[borrower]) return false;
        if (address(badDebt) == address(0)) return false;

        TierConfig memory config = tiers[_getTier(scorer.getScore(borrower))];
        return block.timestamp > loan.dueDate + (config.gracePeriodDays * 1 days);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Core loan actions
    // ─────────────────────────────────────────────────────────────────────────

    function requestLoan(uint256 amount, uint256 collateral, address borrower, bool isUnsecured)
        external
        nonReentrant
        whenNotPaused
        onlyNeobank
    {
        if (amount == 0) revert ZeroAmount();
        if (loans[borrower].status == LoanStatus.Active) revert ActiveLoanExists(borrower);

        uint256 score = scorer.getScore(borrower);
        uint8 tier = _getTier(score);
        TierConfig memory config = tiers[tier];

        if (score < config.minScore) revert InsufficientCreditScore(score, config.minScore);
        if (amount > config.maxLoan) revert LoanCapExceeded(amount, config.maxLoan);

        uint256 originationFee = (amount * feeConfig.originationFeeBps) / 10000;
        uint256 netPrincipal = amount - originationFee;

        if (isUnsecured) {
            if (!config.allowsUnsecured) revert UnsecuredNotAllowed();
            if (collateral > 0) revert CollateralNotRequired();
        } else {
            if (collateral == 0) revert InsufficientCollateral(0, (amount * 10_000) / config.ltvBps);

            if (config.ltvBps < 10000) {
                uint256 maxLoanFromCollateral = (collateral * config.ltvBps) / 10_000;
                if (amount > maxLoanFromCollateral) {
                    revert InsufficientCollateral(collateral, (amount * 10_000) / config.ltvBps);
                }
            }

            uint256 initialHealthFactor = (collateral * 1e18) / (netPrincipal + originationFee);
            if (initialHealthFactor < MIN_HEALTH_FACTOR) {
                revert HealthFactorTooLow(initialHealthFactor, MIN_HEALTH_FACTOR);
            }
        }

        uint256 availableLiquidity = totalLiquidity - activeLoanVolume;
        uint256 reserveRequirement = (totalLiquidity * LIQUIDITY_RESERVE_BPS) / 10_000;
        if (amount > availableLiquidity - reserveRequirement) {
            revert LoanCapExceeded(amount, availableLiquidity - reserveRequirement);
        }

        if (collateral > 0) qusdc.safeTransferFrom(msg.sender, address(this), collateral);

        if (originationFee > 0) {
            qusdc.safeTransferFrom(msg.sender, protocolTreasury, originationFee);
            totalOriginationFees += originationFee;
        }

        loans[borrower] = Loan({
            principal: netPrincipal,
            collateral: isUnsecured ? 0 : collateral,
            interestRateBps: config.interestRateBps,
            issuedAt: block.timestamp,
            dueDate: block.timestamp + (config.tenureMonths * 30 days),
            repaid: 0,
            originationFee: originationFee,
            status: LoanStatus.Active
        });

        isUnsecuredLoan[borrower] = isUnsecured;
        activeLoanVolume += netPrincipal;

        qusdc.safeTransfer(borrower, netPrincipal);

        emit LoanRequested(
            borrower,
            netPrincipal,
            originationFee,
            isUnsecured ? 0 : collateral,
            tier,
            config.interestRateBps,
            isUnsecured
        );

        if (!isUnsecured && collateral > 0) {
            emit HealthFactorUpdated(borrower, getHealthFactor(borrower));
        }
    }

    function getRepaymentAmount(address borrower)
        public
        view
        returns (uint256 totalDue, uint256 interestAccrued, uint256 lateFee)
    {
        Loan memory loan = loans[borrower];
        if (loan.status != LoanStatus.Active) return (0, 0, 0);

        uint256 timeElapsed = block.timestamp - loan.issuedAt;
        uint256 annualInterest = (loan.principal * loan.interestRateBps) / 10_000;
        interestAccrued = (annualInterest * timeElapsed) / 365 days;

        lateFee = 0;
        if (block.timestamp > loan.dueDate) {
            uint256 daysLate = (block.timestamp - loan.dueDate) / 1 days;
            uint256 outstanding = loan.principal + interestAccrued - loan.repaid;
            lateFee = (outstanding * feeConfig.lateFeeBps * daysLate) / (10000 * 30);
        }

        totalDue = loan.principal + interestAccrued + lateFee - loan.repaid;
    }

    function repayLoan(address borrower, uint256 payment) external nonReentrant whenNotPaused onlyNeobank {
        Loan storage loan = loans[borrower];
        if (loan.status != LoanStatus.Active) revert LoanNotFound(borrower);

        (uint256 totalDue, uint256 interestAccrued, uint256 lateFee) = getRepaymentAmount(borrower);
        if (payment > totalDue) payment = totalDue;
        if (payment == 0) revert PaymentBelowMinimum(0, 1);

        uint256 principalOutstanding = loan.principal > loan.repaid ? loan.principal - loan.repaid : 0;
        uint256 interestPortion = payment > principalOutstanding ? payment - principalOutstanding : 0;
        uint256 principalPortion = payment - interestPortion;

        uint256 totalFees = interestPortion + lateFee;
        uint256 protocolFee = (totalFees * feeConfig.protocolInterestShareBps) / 10000;
        uint256 lpYield = totalFees - protocolFee;

        qusdc.safeTransferFrom(msg.sender, address(this), payment);

        if (protocolFee > 0) {
            qusdc.safeTransfer(protocolTreasury, protocolFee);
            totalInterestFees += protocolFee;
        }

        if (lateFee > 0) {
            totalLateFees += lateFee;
            emit LateFeeApplied(borrower, lateFee);
        }

        if (lpYield > 0) {
            qusdc.approve(address(vault), lpYield);
            vault.receiveInterest(lpYield);
        }

        if (principalPortion > 0) activeLoanVolume -= principalPortion;
        loan.repaid += payment;

        if (loan.repaid >= loan.principal + interestAccrued + lateFee) {
            loan.status = LoanStatus.Repaid;
            if (!isUnsecuredLoan[borrower] && loan.collateral > 0) {
                qusdc.safeTransfer(borrower, loan.collateral);
            }
            isUnsecuredLoan[borrower] = false;
        } else {
            if (!isUnsecuredLoan[borrower] && loan.collateral > 0) {
                emit HealthFactorUpdated(borrower, getHealthFactor(borrower));
            }
        }

        emit LoanRepaid(borrower, principalPortion, interestPortion, protocolFee, lpYield);
    }

    function liquidate(address borrower) external nonReentrant whenNotPaused onlyLiquidator {
        Loan storage loan = loans[borrower];
        if (loan.status != LoanStatus.Active) revert LoanNotFound(borrower);
        if (isUnsecuredLoan[borrower] || loan.collateral == 0) revert NoCollateralToLiquidate();

        if (!isLiquidatable(borrower)) {
            TierConfig memory config = tiers[_getTier(scorer.getScore(borrower))];
            uint256 defaultTime = loan.dueDate + (config.gracePeriodDays * 1 days);
            revert DefaultTooEarly(defaultTime);
        }

        loan.status = LoanStatus.Defaulted;
        activeLoanVolume -= loan.principal;

        uint256 totalCollateral = loan.collateral;
        uint256 protocolFee = (totalCollateral * feeConfig.liquidationFeeBps) / 10000;
        uint256 liquidatorBonus = (totalCollateral * feeConfig.liquidatorIncentiveBps) / 10000;

        (uint256 totalDue,,) = getRepaymentAmount(borrower);
        uint256 recoverable = totalCollateral > totalDue ? totalDue : totalCollateral;
        uint256 loss = totalDue > totalCollateral ? totalDue - totalCollateral : 0;

        uint256 liquidatorShare = liquidatorBonus;
        uint256 remainingAfterProtocol = totalCollateral - protocolFee;

        if (remainingAfterProtocol > liquidatorBonus + recoverable) {
            liquidatorShare = liquidatorBonus + recoverable;
        }

        uint256 protocolShare = protocolFee + (recoverable > liquidatorBonus ? recoverable - liquidatorBonus : 0);
        uint256 borrowerRefund =
            totalCollateral > protocolShare + liquidatorShare ? totalCollateral - protocolShare - liquidatorShare : 0;

        if (protocolFee > 0) {
            qusdc.safeTransfer(protocolTreasury, protocolFee);
            totalLiquidationFees += protocolFee;
        }

        qusdc.safeTransfer(msg.sender, liquidatorShare);
        if (borrowerRefund > 0) qusdc.safeTransfer(borrower, borrowerRefund);

        loan.status = LoanStatus.Liquidated;
        isUnsecuredLoan[borrower] = false;

        emit LoanLiquidated(borrower, msg.sender, totalCollateral, protocolFee, liquidatorShare, borrowerRefund);
        emit LoanDefaulted(borrower, loss);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Bad debt lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Declare an unsecured overdue loan as bad debt, minting a resaleable NFT.
     * @dev Callable by authorized liquidators once grace period has elapsed.
     *      The NFT is minted to the borrower (soulbound until settlement) and the
     *      loan is removed from activeLoanVolume so liquidity is freed for new loans.
     *      QIELending must be registered as an authorized minter on QIEBadDebt.
     * @param borrower Address of the defaulted borrower.
     */
    function declareBadDebt(address borrower) external nonReentrant whenNotPaused onlyLiquidator {
        if (address(badDebt) == address(0)) revert BadDebtNotConfigured();

        Loan storage loan = loans[borrower];
        if (loan.status != LoanStatus.Active) revert LoanNotFound(borrower);
        if (!isUnsecuredLoan[borrower]) revert NoCollateralToLiquidate(); // use liquidate() for secured
        if (activeBadDebtToken[borrower] != 0) revert BadDebtAlreadyDeclared(borrower);

        if (!isEligibleForBadDebt(borrower)) {
            TierConfig memory config = tiers[_getTier(scorer.getScore(borrower))];
            uint256 eligibleAt = loan.dueDate + (config.gracePeriodDays * 1 days);
            revert DefaultTooEarly(eligibleAt);
        }

        (, uint256 interestAccrued, uint256 lateFee) = getRepaymentAmount(borrower);

        uint256 principalLost = loan.principal - loan.repaid;
        uint8 tier = _getTier(scorer.getScore(borrower));

        // Mark loan as bad debt before external call (checks-effects-interactions).
        loan.status = LoanStatus.BadDebt;
        activeLoanVolume -= loan.principal;
        isUnsecuredLoan[borrower] = false;

        // Mint bad debt NFT — this contract must be an authorized minter on QIEBadDebt.
        uint256 tokenId = badDebt.mintBadDebt(borrower, principalLost, interestAccrued, lateFee, tier);

        activeBadDebtToken[borrower] = tokenId;

        emit BadDebtDeclared(borrower, tokenId, principalLost, interestAccrued, lateFee, tier);
        emit LoanDefaulted(borrower, principalLost + interestAccrued + lateFee);
    }

    /**
     * @notice Settle a bad debt NFT after a buyer has negotiated recovery with the borrower.
     * @dev Called by the neobank when a debt buyer or the borrower pays the recovery amount.
     *      Burns the bad debt NFT and distributes proceeds: protocol treasury gets
     *      `protocolInterestShareBps` of recovered amount, remainder goes to the vault (LPs).
     *      Any shortfall vs original principal is the economic loss already recognized at
     *      declareBadDebt() time.
     * @param borrower   Original borrower whose bad debt is being settled.
     * @param recovered  Total QUSDC recovered. Caller must have approved this amount.
     */
    function settleBadDebt(address borrower, uint256 recovered) external nonReentrant whenNotPaused onlyNeobank {
        if (address(badDebt) == address(0)) revert BadDebtNotConfigured();

        uint256 tokenId = activeBadDebtToken[borrower];
        if (tokenId == 0) revert BadDebtNotActive(borrower);

        // Verify the NFT still exists on the bad debt contract.
        (, bool exists,) = badDebt.getBadDebtInfo(tokenId);
        if (!exists) revert BadDebtNotActive(borrower);

        // Receive recovery funds from caller (debt buyer or borrower).
        if (recovered > 0) {
            qusdc.safeTransferFrom(msg.sender, address(this), recovered);
        }

        // Distribute proceeds.
        uint256 protocolShare = (recovered * feeConfig.protocolInterestShareBps) / 10000;
        uint256 vaultShare = recovered - protocolShare;

        if (protocolShare > 0) {
            qusdc.safeTransfer(protocolTreasury, protocolShare);
        }

        if (vaultShare > 0) {
            qusdc.approve(address(vault), vaultShare);
            vault.receiveInterest(vaultShare);
        }

        // Clear tracking before external burn call.
        activeBadDebtToken[borrower] = 0;

        // Burn the NFT.
        badDebt.burnOnRepayment(tokenId, recovered);

        emit BadDebtSettled(borrower, tokenId, recovered, protocolShare, vaultShare);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Liquidity management
    // ─────────────────────────────────────────────────────────────────────────

    function addLiquidity(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        qusdc.safeTransferFrom(msg.sender, address(this), amount);
        totalLiquidity += amount;
        emit LiquidityAdded(msg.sender, amount);
    }

    function removeLiquidity(uint256 amount) external nonReentrant onlyOwner {
        uint256 available = totalLiquidity - activeLoanVolume;
        if (amount > available) revert LoanCapExceeded(amount, available);
        qusdc.safeTransfer(msg.sender, amount);
        totalLiquidity -= amount;
        emit LiquidityRemoved(msg.sender, amount);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // View / analytics
    // ─────────────────────────────────────────────────────────────────────────

    function getLoanTerms(address user)
        external
        view
        returns (uint8 tier, uint256 maxLoan, uint256 interestRateBps, uint256 requiredCollateral, uint256 currentScore)
    {
        currentScore = scorer.getScore(user);
        tier = _getTier(currentScore);
        TierConfig memory config = tiers[tier];
        maxLoan = config.maxLoan;
        interestRateBps = config.interestRateBps;
        requiredCollateral = config.allowsUnsecured ? 0 : (config.maxLoan * 10_000) / config.ltvBps;
    }

    function getLoanDetails(address borrower)
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
            uint256 interestAccrued,
            uint256 healthFactor,
            bool unsecured,
            bool liquidatable
        )
    {
        Loan memory loan = loans[borrower];
        principal = loan.principal;
        collateral = loan.collateral;
        interestRateBps = loan.interestRateBps;
        issuedAt = loan.issuedAt;
        dueDate = loan.dueDate;
        repaid = loan.repaid;
        status = uint8(loan.status);
        unsecured = isUnsecuredLoan[borrower];
        (totalDue, interestAccrued,) = getRepaymentAmount(borrower);
        healthFactor = getHealthFactor(borrower);
        liquidatable = isLiquidatable(borrower);
    }

    function getFeeAnalytics()
        external
        view
        returns (
            uint256 originationFees,
            uint256 interestFees,
            uint256 liquidationFees,
            uint256 lateFees,
            uint256 totalFees
        )
    {
        return (
            totalOriginationFees,
            totalInterestFees,
            totalLiquidationFees,
            totalLateFees,
            totalOriginationFees + totalInterestFees + totalLiquidationFees + totalLateFees
        );
    }

    function utilizationRate() external view returns (uint256) {
        return totalLiquidity > 0 ? (activeLoanVolume * 10000) / totalLiquidity : 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Credit score data feeds
    // ─────────────────────────────────────────────────────────────────────────

    function onTimeRepayments(address user) external view returns (uint256) {
        Loan memory loan = loans[user];
        return (loan.status == LoanStatus.Repaid && block.timestamp <= loan.dueDate) ? 1 : 0;
    }

    function lateRepayments(address user) external view returns (uint256) {
        Loan memory loan = loans[user];
        return (loan.status == LoanStatus.Repaid && block.timestamp > loan.dueDate) ? 1 : 0;
    }

    function totalRepayments(address user) external view returns (uint256) {
        Loan memory loan = loans[user];
        return (loan.status == LoanStatus.Repaid || loan.repaid > 0) ? 1 : 0;
    }

    function defaultedLoans(address user) external view returns (uint256) {
        Loan memory loan = loans[user];
        return (loan.status == LoanStatus.Defaulted || loan.status == LoanStatus.Liquidated
                    || loan.status == LoanStatus.BadDebt)
            ? 1
            : 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────────────────

    function _getTier(uint256 score) internal pure returns (uint8) {
        if (score >= 750) return 3;
        if (score >= 650) return 2;
        if (score >= 550) return 1;
        return 0;
    }
}
