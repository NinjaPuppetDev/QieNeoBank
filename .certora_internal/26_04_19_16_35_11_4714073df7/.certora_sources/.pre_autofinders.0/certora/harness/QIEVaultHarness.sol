// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "../../src/QIEVault.sol";
import "./QUSDCMock.sol";

/**
 * @title QIEVaultHarness
 * @notice Certora verification harness for QIEVault.
 *
 * Why a harness?
 *   Certora's Prover operates on the public/external ABI. Internal and
 *   private functions are invisible to the spec. This harness inherits
 *   QIEVault and re-exports everything the spec needs.
 *
 * The balanceOf resolution problem and its fix:
 *   QIEVault.totalAssets() calls IERC20(asset()).balanceOf(address(this)).
 *   asset() is stored as an immutable set in the ERC4626 constructor —
 *   a runtime address the Certora Prover cannot statically resolve. The
 *   prover falls back to NONDET, which freely assigns MAX_UINT256, making
 *   totalAssets() return MAX_UINT256 and poisoning every share-math rule.
 *
 *   Fix: pass a known QUSDCMock instance as the underlying asset. Certora
 *   now sees a concrete contract for the IERC20(asset()) call and can
 *   resolve balanceOf to QUSDCMock.balanceOf(), whose return value comes
 *   from the controllable balances[address] mapping. The spec hooks that
 *   mapping with a ghost to bound it to a realistic value.
 *
 *   No production code is modified. totalAssets() is NOT overridden here
 *   because QIEVault.totalAssets() already overrides ERC4626 but is not
 *   marked virtual, preventing a second override.
 *
 * Design rules:
 *   - NEVER override deposit/withdraw/redeem/receiveInterest logic.
 *   - NEVER add state variables — ghosts and state live in spec/mock.
 *   - All exposed functions are pure/view wrappers.
 */
contract QIEVaultHarness is QIEVault {
    using Math for uint256;

    /// @notice The mock underlying asset wired in at construction.
    ///         Exposed so the spec can access balances[vault] directly.
    QUSDCMock public immutable qusdcMock;

    constructor() QIEVault(IERC20(address(new QUSDCMock()))) {
        qusdcMock = QUSDCMock(asset());
    }

    // ── Convenience view ──────────────────────────────────────────────────────

    /**
     * @notice Returns the underlying QUSDC balance held by this vault.
     * @dev    Reads from QUSDCMock.balances[address(this)], the same value
     *         that totalAssets() uses. Lets the spec verify TA1 without
     *         duplicating the balanceOf call.
     */
    function underlyingBalance() external view returns (uint256) {
        return qusdcMock.balanceOf(address(this));
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