// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.6.0) (utils/Memory.sol)

pragma solidity ^0.8.24;

import {Panic} from "./Panic.sol";
import {Math} from "./math/Math.sol";

/**
 * @dev Utilities to manipulate memory.
 *
 * Memory is a contiguous and dynamic byte array in which Solidity stores non-primitive types.
 * This library provides functions to manipulate pointers to this dynamic array and work with slices of it.
 *
 * Slices provide a view into a portion of memory without copying data, enabling efficient substring operations.
 *
 * WARNING: When manipulating memory pointers or slices, make sure to follow the Solidity documentation
 * guidelines for https://docs.soliditylang.org/en/v0.8.20/assembly.html#memory-safety[Memory Safety].
 */
library Memory {
    type Pointer is bytes32;

    /// @dev Returns a `Pointer` to the current free `Pointer`.
    function getFreeMemoryPointer() internal pure returns (Pointer ptr) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01540000, 1037618708820) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01540001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01540004, 0) }
        assembly ("memory-safe") {
            ptr := mload(0x40)
        }
    }

    /**
     * @dev Sets the free `Pointer` to a specific value.
     *
     * The solidity memory layout requires that the FMP is never set to a value lower than 0x80. Setting the
     * FMP to a value lower than 0x80 may cause unexpected behavior. Deallocating all memory can be achieved by
     * setting the FMP to 0x80.
     *
     * WARNING: Everything after the pointer may be overwritten.
     **/
    function unsafeSetFreeMemoryPointer(Pointer ptr) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01550000, 1037618708821) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01550001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01550005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01556000, ptr) }
        assembly ("memory-safe") {
            mstore(0x40, ptr)
        }
    }

    /// @dev Move a pointer forward by a given offset.
    function forward(Pointer ptr, uint256 offset) internal pure returns (Pointer) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01570000, 1037618708823) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01570001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01570005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01576001, offset) }
        return Pointer.wrap(bytes32(uint256(Pointer.unwrap(ptr)) + offset));
    }

    /// @dev Equality comparator for memory pointers.
    function equal(Pointer ptr1, Pointer ptr2) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01580000, 1037618708824) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01580001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01580005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01586001, ptr2) }
        return Pointer.unwrap(ptr1) == Pointer.unwrap(ptr2);
    }

    type Slice is bytes32;

    /// @dev Get a slice representation of a bytes object in memory
    function asSlice(bytes memory self) internal pure returns (Slice result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01560000, 1037618708822) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01560001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01560005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01566000, self) }
        assembly ("memory-safe") {
            result := or(shl(128, mload(self)), add(self, 0x20))
        }
    }

    /// @dev Returns the length of a given slice (equiv to self.length for calldata slices)
    function length(Slice self) internal pure returns (uint256 result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01590000, 1037618708825) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01590001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01590005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01596000, self) }
        assembly ("memory-safe") {
            result := shr(128, self)
        }
    }

    /// @dev Offset a memory slice (equivalent to self[offset:] for calldata slices)
    function slice(Slice self, uint256 offset) internal pure returns (Slice) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015a0000, 1037618708826) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015a0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015a6001, offset) }
        if (offset > length(self)) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        return _asSlice(length(self) - offset, forward(_pointer(self), offset));
    }

    /// @dev Offset and cut a Slice (equivalent to self[offset:offset+len] for calldata slices)
    function slice(Slice self, uint256 offset, uint256 len) internal pure returns (Slice) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015b0000, 1037618708827) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015b0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015b0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015b6002, len) }
        if (offset + len > length(self)) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        return _asSlice(len, forward(_pointer(self), offset));
    }

    /**
     * @dev Read a bytes32 buffer from a given Slice at a specific offset
     *
     * NOTE: If offset > length(slice) - 0x20, part of the return value will be out of bound of the slice. These bytes are zeroed.
     */
    function load(Slice self, uint256 offset) internal pure returns (bytes32 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015c0000, 1037618708828) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015c0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015c0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015c6001, offset) }
        uint256 outOfBoundBytes = Math.saturatingSub(0x20 + offset, length(self));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000018,outOfBoundBytes)}
        if (outOfBoundBytes > 0x1f) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);

        assembly ("memory-safe") {
            value := and(mload(add(and(self, shr(128, not(0))), offset)), shl(mul(8, outOfBoundBytes), not(0)))
        }
    }

    /// @dev Extract the data corresponding to a Slice (allocate new memory)
    function toBytes(Slice self) internal pure returns (bytes memory result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015d0000, 1037618708829) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015d6000, self) }
        uint256 len = length(self);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000019,len)}
        Memory.Pointer ptr = _pointer(self);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001a,0)}
        assembly ("memory-safe") {
            result := mload(0x40)
            mstore(result, len)
            mcopy(add(result, 0x20), ptr, len)
            mstore(0x40, add(add(result, len), 0x20))
        }
    }

    /// @dev Returns true if the two slices contain the same data.
    function equal(Slice a, Slice b) internal pure returns (bool result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015e0000, 1037618708830) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015e0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015e6001, b) }
        Memory.Pointer ptrA = _pointer(a);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001b,0)}
        Memory.Pointer ptrB = _pointer(b);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001c,0)}
        uint256 lenA = length(a);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001d,lenA)}
        uint256 lenB = length(b);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001e,lenB)}
        assembly ("memory-safe") {
            result := eq(keccak256(ptrA, lenA), keccak256(ptrB, lenB))
        }
    }

    /// @dev Returns true if the memory occupied by the slice is reserved (i.e. before the free memory pointer)
    function isReserved(Slice self) internal pure returns (bool result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015f0000, 1037618708831) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff015f6000, self) }
        Memory.Pointer fmp = getFreeMemoryPointer();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001f,0)}
        Memory.Pointer end = forward(_pointer(self), length(self));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010020,0)}
        assembly ("memory-safe") {
            result := iszero(lt(fmp, end)) // end <= fmp
        }
    }

    /**
     * @dev Private helper: create a slice from raw values (length and pointer)
     *
     * NOTE: this function MUST NOT be called with `len` or `ptr` that exceed `2**128-1`. This should never be
     * the case of slices produced by `asSlice(bytes)`, and function that reduce the scope of slices
     * (`slice(Slice,uint256)` and `slice(Slice,uint256, uint256)`) should not cause this issue if the parent slice is
     * correct.
     */
    function _asSlice(uint256 len, Memory.Pointer ptr) private pure returns (Slice result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01600000, 1037618708832) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01600001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01600005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01606001, ptr) }
        assembly ("memory-safe") {
            result := or(shl(128, len), ptr)
        }
    }

    /// @dev Returns the memory location of a given slice (equiv to self.offset for calldata slices)
    function _pointer(Slice self) private pure returns (Memory.Pointer result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01610000, 1037618708833) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01610001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01610005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01616000, self) }
        assembly ("memory-safe") {
            result := and(self, shr(128, not(0)))
        }
    }
}
