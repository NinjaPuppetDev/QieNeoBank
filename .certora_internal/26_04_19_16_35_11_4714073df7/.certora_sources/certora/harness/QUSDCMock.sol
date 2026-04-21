// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title QUSDCMock
 * @notice Minimal ERC20 mock for Certora verification of QIEVault.
 *
 * The problem this solves:
 *   QIEVault.totalAssets() calls IERC20(asset()).balanceOf(address(this)).
 *   asset() is a runtime address, so Certora cannot resolve the callee.
 *   NONDET fills the return with MAX_UINT256, poisoning every share-math rule.
 *
 * The fix:
 *   QIEVaultHarness passes THIS contract as the underlying asset in its
 *   constructor. Certora resolves balanceOf to this known implementation.
 *   The spec constrains balances[vaultAddress] via a ghost hook on this
 *   mapping, giving the prover a concrete bounded value for totalAssets().
 */
contract QUSDCMock is ERC20 {
    /// @notice Per-address controllable balances.
    /// The spec hooks Sstore/Sload on this mapping to ghost the vault's balance.
    mapping(address => uint256) public balances;

    constructor() ERC20("QIE USD Coin", "QUSDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address, uint256) public override returns (bool) {
        return true;
    }

    function transferFrom(address, address, uint256) public override returns (bool) {
        return true;
    }

    function approve(address, uint256) public override returns (bool) {
        return true;
    }
}