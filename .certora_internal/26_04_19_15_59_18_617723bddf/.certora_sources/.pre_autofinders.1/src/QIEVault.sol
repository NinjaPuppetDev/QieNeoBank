// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title QIEVault
 * @notice ERC4626 vault for QIE Neobank deposits.
 *         Yield comes from lending interest spread, not prediction markets.
 *         Share price appreciates as QIELending returns interest via receiveInterest().
 * @dev    Deposit metadata (firstDepositAt, totalDeposited, depositCount) is
 *         read by CreditScore to compute the on-chain credit profile.
 */
contract QIEVault is ERC4626, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ── Errors ─────────────────────────────────────────────────
    error ZeroAmount();
    error ZeroAddress();
    error NotLending();
    error MinSharesNotMet(uint256 got, uint256 minimum);
    error BelowMinDeposit(uint256 got, uint256 minimum);

    // ── Constants ──────────────────────────────────────────────
    /// @notice Minimum deposit amount (1 QUSDC = 1e6)
    uint256 public constant MIN_DEPOSIT = 1e6;

    // ── State ──────────────────────────────────────────────────
    /// @notice Address authorized to call receiveInterest (QIELending)
    address public lendingContract;

    // Credit score data — read by CreditScore contract
    mapping(address => uint256) public firstDepositAt;
    mapping(address => uint256) public totalDeposited;
    mapping(address => uint256) public depositCount;

    // ── Events ─────────────────────────────────────────────────
    event InterestReceived(address indexed from, uint256 amount);
    event LendingContractSet(address indexed lending);

    // ── Constructor ────────────────────────────────────────────
    constructor(IERC20 _qusdc) ERC4626(_qusdc) ERC20("QIE Neobank Shares", "qNEO") Ownable(msg.sender) {}

    // ── Admin ──────────────────────────────────────────────────
    function setLendingContract(address _lending) external onlyOwner {
        if (_lending == address(0)) revert ZeroAddress();
        lendingContract = _lending;
        emit LendingContractSet(_lending);
    }

    // ── Inflation attack protection (virtual offset) ────────────
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + 1;
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 3; // 1000x virtual offset — strong inflation protection
    }

    // ── Deposit / Withdraw ─────────────────────────────────────
    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256 shares) {
        if (assets == 0) revert ZeroAmount();
        if (assets < MIN_DEPOSIT) revert BelowMinDeposit(assets, MIN_DEPOSIT);
        if (receiver == address(0)) revert ZeroAddress();

        shares = super.deposit(assets, receiver);

        // Track deposit metadata for CreditScore
        if (firstDepositAt[receiver] == 0) {
            firstDepositAt[receiver] = block.timestamp;
        }
        totalDeposited[receiver] += assets;
        depositCount[receiver]++;
    }

    function withdraw(uint256 assets, address receiver, address owner_)
        public
        override
        nonReentrant
        returns (uint256 shares)
    {
        if (assets == 0) revert ZeroAmount();
        return super.withdraw(assets, receiver, owner_);
    }

    function redeem(uint256 shares, address receiver, address owner_)
        public
        override
        nonReentrant
        returns (uint256 assets)
    {
        if (shares == 0) revert ZeroAmount();
        return super.redeem(shares, receiver, owner_);
    }

    // ── Yield from lending interest ────────────────────────────
    /**
     * @notice Called by QIELending when borrowers repay interest.
     *         Tokens must be transferred to this contract before calling.
     *         totalAssets() increases automatically, appreciating share price
     *         for all depositors proportionally.
     * @param amount Interest amount being returned to the vault
     */
    function receiveInterest(uint256 amount) external {
        if (msg.sender != lendingContract) revert NotLending();
        // Tokens already transferred by QIELending before this call.
        // ERC4626 share price appreciates automatically via totalAssets().
        emit InterestReceived(msg.sender, amount);
    }
}
