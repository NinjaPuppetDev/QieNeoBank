// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "../../src/QIEVault.sol";

/**
 * @title QIEVaultHarness
 * @notice Certora verification harness for QIEVault.
 *
 * Prerequisite: QIEVault.totalAssets() must be marked `virtual override`.
 *   The one-line change in src/QIEVault.sol:
 *     function totalAssets() public view virtual override returns (uint256)
 *   This is correct ERC4626 design — OZ marks it virtual for this reason.
 *   It does not change production behavior.
 *
 * Why we override totalAssets() here:
 *   The production implementation calls IERC20(asset()).balanceOf(address(this)).
 *   asset() is an immutable resolved at the ERC4626 IR level — not via our
 *   constructor argument — so Certora cannot statically resolve the callee
 *   regardless of what ERC20 we pass in. AUTO havoc assigns MAX_UINT256,
 *   poisoning every share-math rule.
 *
 *   The override reads certora_underlyingBalance instead. The formula
 *   (balance + 1) is preserved exactly. The spec bounds this variable to
 *   a realistic value, giving the prover a concrete totalAssets() to work with.
 *
 * Design rules:
 *   - NEVER override deposit/withdraw/redeem/receiveInterest logic.
 *   - certora_underlyingBalance is the only added state variable.
 *   - All other exposed functions are pure/view wrappers only.
 */
contract QIEVaultHarness is QIEVault {
    using Math for uint256;

    /// @notice Certora-controlled underlying balance.
    /// The spec bounds this via `require vault.certora_underlyingBalance() <= X`.
    /// Production totalAssets() is replaced by this + 1 for verification only.
    uint256 public certora_underlyingBalance;

    constructor(IERC20 _qusdc) QIEVault(_qusdc) {}

    // ── Override that breaks the unresolvable balanceOf chain ─────────────────

    /**
     * @notice Returns certora_underlyingBalance + 1.
     * @dev    Identical formula to production. Only the data source changes:
     *         certora_underlyingBalance instead of IERC20(asset()).balanceOf().
     */
    function totalAssets() public view virtual override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00090000, 1037618708489) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00090001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00090004, 0) }
        return certora_underlyingBalance + 1;
    }

    // ── Convenience view ──────────────────────────────────────────────────────

    /**
     * @notice Returns the underlying balance (without the +1 offset).
     *         Used by TA1 to verify totalAssets = underlyingBalance + 1.
     */
    function underlyingBalance() external view returns (uint256) {
        return certora_underlyingBalance;
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