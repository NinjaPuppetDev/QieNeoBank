// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.6.0) (utils/LowLevelCall.sol)

pragma solidity ^0.8.20;

/**
 * @dev Library of low level call functions that implement different calling strategies to deal with the return data.
 *
 * WARNING: Using this library requires an advanced understanding of Solidity and how the EVM works. It is recommended
 * to use the {Address} library instead.
 */
library LowLevelCall {
    /// @dev Performs a Solidity function call using a low level `call` and ignoring the return data.
    function callNoReturn(address target, bytes memory data) internal returns (bool success) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01480000, 1037618708808) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01480001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01480005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01486001, data) }
        return callNoReturn(target, 0, data);
    }

    /// @dev Same as {callNoReturn-address-bytes}, but allows specifying the value to be sent in the call.
    function callNoReturn(address target, uint256 value, bytes memory data) internal returns (bool success) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01490000, 1037618708809) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01490001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01490005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01496002, data) }
        assembly ("memory-safe") {
            success := call(gas(), target, value, add(data, 0x20), mload(data), 0x00, 0x00)
        }
    }

    /// @dev Performs a Solidity function call using a low level `call` and returns the first 64 bytes of the result
    /// in the scratch space of memory. Useful for functions that return a tuple with two single-word values.
    ///
    /// WARNING: Do not assume that the results are zero if `success` is false. Memory can be already allocated
    /// and this function doesn't zero it out.
    function callReturn64Bytes(
        address target,
        bytes memory data
    ) internal returns (bool success, bytes32 result1, bytes32 result2) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b0000, 1037618708811) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b6001, data) }
        return callReturn64Bytes(target, 0, data);
    }

    /// @dev Same as {callReturn64Bytes-address-bytes}, but allows specifying the value to be sent in the call.
    function callReturn64Bytes(
        address target,
        uint256 value,
        bytes memory data
    ) internal returns (bool success, bytes32 result1, bytes32 result2) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c0000, 1037618708812) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c6002, data) }
        assembly ("memory-safe") {
            success := call(gas(), target, value, add(data, 0x20), mload(data), 0x00, 0x40)
            result1 := mload(0x00)
            result2 := mload(0x20)
        }
    }

    /// @dev Performs a Solidity function call using a low level `staticcall` and ignoring the return data.
    function staticcallNoReturn(address target, bytes memory data) internal view returns (bool success) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a0000, 1037618708810) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a6001, data) }
        assembly ("memory-safe") {
            success := staticcall(gas(), target, add(data, 0x20), mload(data), 0x00, 0x00)
        }
    }

    /// @dev Performs a Solidity function call using a low level `staticcall` and returns the first 64 bytes of the result
    /// in the scratch space of memory. Useful for functions that return a tuple with two single-word values.
    ///
    /// WARNING: Do not assume that the results are zero if `success` is false. Memory can be already allocated
    /// and this function doesn't zero it out.
    function staticcallReturn64Bytes(
        address target,
        bytes memory data
    ) internal view returns (bool success, bytes32 result1, bytes32 result2) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d0000, 1037618708813) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d6001, data) }
        assembly ("memory-safe") {
            success := staticcall(gas(), target, add(data, 0x20), mload(data), 0x00, 0x40)
            result1 := mload(0x00)
            result2 := mload(0x20)
        }
    }

    /// @dev Performs a Solidity function call using a low level `delegatecall` and ignoring the return data.
    function delegatecallNoReturn(address target, bytes memory data) internal returns (bool success) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0000, 1037618708814) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e6001, data) }
        assembly ("memory-safe") {
            success := delegatecall(gas(), target, add(data, 0x20), mload(data), 0x00, 0x00)
        }
    }

    /// @dev Performs a Solidity function call using a low level `delegatecall` and returns the first 64 bytes of the result
    /// in the scratch space of memory. Useful for functions that return a tuple with two single-word values.
    ///
    /// WARNING: Do not assume that the results are zero if `success` is false. Memory can be already allocated
    /// and this function doesn't zero it out.
    function delegatecallReturn64Bytes(
        address target,
        bytes memory data
    ) internal returns (bool success, bytes32 result1, bytes32 result2) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f0000, 1037618708815) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f6001, data) }
        assembly ("memory-safe") {
            success := delegatecall(gas(), target, add(data, 0x20), mload(data), 0x00, 0x40)
            result1 := mload(0x00)
            result2 := mload(0x20)
        }
    }

    /// @dev Returns the size of the return data buffer.
    function returnDataSize() internal pure returns (uint256 size) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01500000, 1037618708816) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01500001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01500004, 0) }
        assembly ("memory-safe") {
            size := returndatasize()
        }
    }

    /// @dev Returns a buffer containing the return data from the last call.
    function returnData() internal pure returns (bytes memory result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01510000, 1037618708817) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01510001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01510004, 0) }
        assembly ("memory-safe") {
            result := mload(0x40)
            mstore(result, returndatasize())
            returndatacopy(add(result, 0x20), 0x00, returndatasize())
            mstore(0x40, add(result, add(0x20, returndatasize())))
        }
    }

    /// @dev Revert with the return data from the last call.
    function bubbleRevert() internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01520000, 1037618708818) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01520001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01520004, 0) }
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            returndatacopy(fmp, 0x00, returndatasize())
            revert(fmp, returndatasize())
        }
    }

    function bubbleRevert(bytes memory returndata) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01530000, 1037618708819) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01530001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01530005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01536000, returndata) }
        assembly ("memory-safe") {
            revert(add(returndata, 0x20), mload(returndata))
        }
    }
}
