// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "../../src/QIEVault.sol";

/**
 * @title QIEVaultHarness
 * @notice Certora verification harness for QIEVault.
 *
 * Why a harness?
 *   Certora's Prover operates on the public/external ABI. Internal and
 *   private functions are invisible to the spec. This harness inherits
 *   QIEVault and re-exports everything the spec needs:
 *
 *   1. _convertToShares / _convertToAssets — used in share-price and
 *      inflation-attack rules.
 *   2. _decimalsOffset — referenced in virtual-offset invariant.
 *   3. Thin wrappers that give the spec deterministic entry points without
 *      changing any logic (no overrides of business logic here).
 *
 * Design rules:
 *   - NEVER override deposit/withdraw/redeem/receiveInterest logic.
 *   - NEVER add state variables — ghosts and hooks live in the spec.
 *   - All exposed functions are pure view wrappers; they cannot mutate state.
 */
contract QIEVaultHarness is QIEVault {
    using Math for uint256;

    constructor(IERC20 _qusdc) QIEVault(_qusdc) {}

    // ─────────────────────────────────────────────────────────────────────────
    // Expose internal conversion math
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Floor-rounded shares for `assets`.
     * @dev    Mirrors what ERC4626.deposit() uses internally (Rounding.Floor).
     *         The spec uses this to assert shares > 0 for valid deposit amounts.
     */
    function convertToShares_exposed(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /**
     * @notice Ceil-rounded shares for `assets` (used by previewDeposit path).
     */
    function convertToSharesCeil_exposed(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    /**
     * @notice Floor-rounded assets for `shares`.
     * @dev    Mirrors what ERC4626.withdraw() uses internally.
     *         The spec uses this to prove share price non-decrease after interest.
     */
    function convertToAssets_exposed(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /**
     * @notice Ceil-rounded assets for `shares` (used by previewRedeem path).
     */
    function convertToAssetsCeil_exposed(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    /**
     * @notice Exposes the virtual decimal offset constant.
     * @dev    Used in the inflation-attack invariant to assert that the
     *         virtual supply offset (10 ** decimalsOffset) is > 0.
     */
    function decimalsOffset_exposed() external pure returns (uint8) {
        return _decimalsOffset();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Convenience view helpers (avoid spec needing to call raw ERC20 selectors)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the underlying QUSDC balance held by this vault.
     * @dev    totalAssets() = underlyingBalance() + 1  (virtual offset).
     *         Having both lets the spec verify the formula as a rule.
     */
    function underlyingBalance() external view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /**
     * @notice Exposes MIN_DEPOSIT as a function so the spec can reference it
     *         without hardcoding the literal 1e6.
     */
    function minDeposit() external pure returns (uint256) {
        return MIN_DEPOSIT;
    }
}