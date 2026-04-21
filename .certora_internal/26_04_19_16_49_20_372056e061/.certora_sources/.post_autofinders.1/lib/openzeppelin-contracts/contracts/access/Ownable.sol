// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f80000, 1037618708728) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f80001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f80004, 0) }
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01010000, 1037618708737) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01010001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01010004, 0) }
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual logInternal262()onlyOwner {
        _transferOwnership(address(0));
    }modifier logInternal262() { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01060000, 1037618708742) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01060001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01060004, 0) } _; }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual logInternal259(newOwner)onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }modifier logInternal259(address newOwner) { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01030000, 1037618708739) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01030001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01030005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01036000, newOwner) } _; }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01020000, 1037618708738) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01020001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01020005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01026000, newOwner) }
        address oldOwner = _owner;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000002,oldOwner)}
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
