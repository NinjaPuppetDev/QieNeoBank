// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ff0000, 1037618708735) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ff0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ff0004, 0) }
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01100000, 1037618708752) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01100001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01100004, 0) }
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012b0000, 1037618708779) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012b0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012b0004, 0) }
        return 18;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01150000, 1037618708757) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01150001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01150004, 0) }
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01090000, 1037618708745) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01090001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01090005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01096000, account) }
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010e0000, 1037618708750) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010e0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010e6001, value) }
        address owner = _msgSender();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000004,owner)}
        _transfer(owner, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010f0000, 1037618708751) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010f0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010f0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010f6001, spender) }
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a0000, 1037618708746) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a6001, value) }
        address owner = _msgSender();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,owner)}
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01160000, 1037618708758) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01160001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01160005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01166002, value) }
        address spender = _msgSender();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,spender)}
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01240000, 1037618708772) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01240001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01240005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01246002, value) }
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01260000, 1037618708774) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01260001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01260005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01266002, value) }
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000008,fromBalance)}
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01270000, 1037618708775) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01270001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01270005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01276001, value) }
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01250000, 1037618708773) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01250001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01250005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01256001, value) }
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01280000, 1037618708776) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01280001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01280005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01286002, value) }
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation sets the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the `transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290000, 1037618708777) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290005, 585) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01296003, emitEvent) }
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012a0000, 1037618708778) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012a0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012a0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012a6002, value) }
        uint256 currentAllowance = allowance(owner, spender);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,currentAllowance)}
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}
