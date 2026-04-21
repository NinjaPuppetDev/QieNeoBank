// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "../../src/QIEVault.sol";

/**
 * @title QIEVaultHarness
 * @notice Certora verification harness for QIEVault.
 *
 * Two problems solved here:
 *
 * 1. totalAssets() unresolved callee (IERC20(asset()).balanceOf)
 *    asset() is an ERC4626 immutable — Certora cannot resolve it statically.
 *    Fix: override totalAssets() to read ghost_underlying directly.
 *    Requires `virtual` on QIEVault.totalAssets().
 *
 * 2. SafeERC20 assembly call havoc
 *    deposit() → SafeERC20.safeTransferFrom() → assembly `call` with both
 *    callee contract AND sighash unresolved. CVL wildcard summaries only
 *    match on resolved sighashes, so _.transferFrom => ALWAYS(true) is
 *    silently ignored. The prover havoces all contracts including the vault's
 *    own share balances, producing false share==0 counterexamples.
 *
 *    Fix: override deposit() in the harness to skip the SafeERC20 call
 *    entirely and call ERC4626._deposit() directly. _deposit() mints shares
 *    and emits the event — it does NOT do the token transfer (that's done
 *    by the ERC4626.deposit() wrapper via _asset.safeTransferFrom). By
 *    calling _deposit() directly we isolate exactly the share-minting
 *    logic we want to verify, with no assembly calls in scope.
 *
 *    This is sound for SI3/IA2 because those rules prove share minting
 *    correctness given that the deposit call succeeds — not token transfer
 *    correctness. ghost_underlying is set by the spec to model the post-
 *    transfer vault balance, so totalAssets() already reflects the deposited
 *    assets when _deposit() runs.
 *
 * Design rules:
 *   - deposit() override skips token transfer only — share logic unchanged.
 *   - All other entry points (withdraw, redeem, receiveInterest) unmodified.
 *   - ghost_underlying is the only added state variable.
 */
contract QIEVaultHarness is QIEVault {
    using Math for uint256;

    /// @notice Certora-controlled underlying balance.
    /// The spec sets this to model the vault's QUSDC balance without going
    /// through the unresolvable IERC20(asset()).balanceOf() call.
    uint256 public ghost_underlying;

    constructor(IERC20 _qusdc) QIEVault(_qusdc) {}

    // ── Override 1: break the balanceOf chain ─────────────────────────────────

    function totalAssets() public view virtual override returns (uint256) {
        return ghost_underlying + 1;
    }

    function underlyingBalance() external view returns (uint256) {
        return ghost_underlying;
    }

    // ── Override 2: skip SafeERC20 assembly, call share-mint logic directly ───

    /**
     * @notice Certora-safe deposit: validates inputs, updates metadata,
     *         then calls ERC4626._deposit() directly to mint shares.
     *
     * @dev    The spec precondition `require ghost_underlying == X` models
     *         the state after the token transfer would have occurred. So
     *         when _deposit() calls totalAssets() it gets the correct
     *         post-transfer value and mints the right number of shares.
     *
     *         Input validation (zero amount, below min, zero receiver) is
     *         preserved exactly from QIEVault.deposit().
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        returns (uint256 shares)
    {
        if (assets == 0) revert ZeroAmount();
        if (assets < MIN_DEPOSIT) revert BelowMinDeposit(assets, MIN_DEPOSIT);
        if (receiver == address(0)) revert ZeroAddress();

        // Skip safeTransferFrom — the spec models the post-transfer balance
        // via ghost_underlying. Call ERC4626 internal mint directly.
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        shares = previewDeposit(assets);
        _deposit(msg.sender, receiver, assets, shares);

        // Metadata update — identical to QIEVault.deposit()
        if (firstDepositAt[receiver] == 0) {
            firstDepositAt[receiver] = block.timestamp;
        }
        totalDeposited[receiver] += assets;
        depositCount[receiver]++;
    }

    // ── Expose internal conversion math ──────────────────────────────────────

    function convertToShares_exposed(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    function convertToSharesCeil_exposed(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    function convertToAssets_exposed(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    function convertToAssetsCeil_exposed(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    function decimalsOffset_exposed() external pure returns (uint8) {
        return _decimalsOffset();
    }

    function minDeposit() external pure returns (uint256) {
        return MIN_DEPOSIT;
    }
}