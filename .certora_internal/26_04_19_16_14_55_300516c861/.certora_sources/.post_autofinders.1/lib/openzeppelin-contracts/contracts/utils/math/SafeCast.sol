// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.6.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX/bool casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in a uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in a uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev A uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01780000, 1037618708856) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01780001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01780005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01786000, value) }
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01790000, 1037618708857) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01790001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01790005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01796000, value) }
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b0000, 1037618708859) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b6000, value) }
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c0000, 1037618708860) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c6000, value) }
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a0000, 1037618708858) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a6000, value) }
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d0000, 1037618708861) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d6000, value) }
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e0000, 1037618708862) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e6000, value) }
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f0000, 1037618708863) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f6000, value) }
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01800000, 1037618708864) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01800001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01800005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01806000, value) }
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01810000, 1037618708865) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01810001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01810005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01816000, value) }
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01820000, 1037618708866) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01820001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01820005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01826000, value) }
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01830000, 1037618708867) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01830001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01830005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01836000, value) }
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01840000, 1037618708868) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01840001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01840005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01846000, value) }
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01850000, 1037618708869) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01850001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01850005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01856000, value) }
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01860000, 1037618708870) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01860001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01860005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01866000, value) }
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01870000, 1037618708871) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01870001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01870005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01876000, value) }
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b10000, 1037618708913) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b16000, value) }
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b00000, 1037618708912) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b06000, value) }
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01af0000, 1037618708911) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01af0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01af0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01af6000, value) }
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b20000, 1037618708914) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b26000, value) }
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b30000, 1037618708915) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b36000, value) }
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b40000, 1037618708916) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b46000, value) }
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b50000, 1037618708917) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b56000, value) }
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b60000, 1037618708918) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b66000, value) }
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b70000, 1037618708919) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b76000, value) }
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b80000, 1037618708920) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01b86000, value) }
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01960000, 1037618708886) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01960001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01960005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01966000, value) }
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01970000, 1037618708887) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01970001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01970005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01976000, value) }
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01980000, 1037618708888) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01980001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01980005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01986000, value) }
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018f0000, 1037618708879) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018f6000, value) }
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01900000, 1037618708880) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01900001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01900005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01906000, value) }
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01910000, 1037618708881) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01910001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01910005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01916000, value) }
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01920000, 1037618708882) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01920001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01920005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01926000, value) }
        downcasted = int248(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000037,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01930000, 1037618708883) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01930001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01930005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01936000, value) }
        downcasted = int240(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000038,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01940000, 1037618708884) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01940001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01940005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01946000, value) }
        downcasted = int232(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000039,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01950000, 1037618708885) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01950001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01950005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01956000, value) }
        downcasted = int224(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003a,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01880000, 1037618708872) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01880001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01880005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01886000, value) }
        downcasted = int216(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003b,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01890000, 1037618708873) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01890001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01890005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01896000, value) }
        downcasted = int208(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003c,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018a0000, 1037618708874) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018a6000, value) }
        downcasted = int200(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003d,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018b0000, 1037618708875) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018b6000, value) }
        downcasted = int192(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003e,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018c0000, 1037618708876) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018c6000, value) }
        downcasted = int184(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003f,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018d0000, 1037618708877) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018d6000, value) }
        downcasted = int176(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000040,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018e0000, 1037618708878) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018e0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff018e6000, value) }
        downcasted = int168(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000041,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01990000, 1037618708889) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01990001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01990005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01996000, value) }
        downcasted = int160(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000042,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019a0000, 1037618708890) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019a6000, value) }
        downcasted = int152(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000043,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019b0000, 1037618708891) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019b6000, value) }
        downcasted = int144(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000044,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019c0000, 1037618708892) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019c6000, value) }
        downcasted = int136(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000045,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019d0000, 1037618708893) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019d6000, value) }
        downcasted = int128(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000046,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019e0000, 1037618708894) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019e0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019e6000, value) }
        downcasted = int120(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000047,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019f0000, 1037618708895) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff019f6000, value) }
        downcasted = int112(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000048,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a00000, 1037618708896) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a06000, value) }
        downcasted = int104(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000049,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a10000, 1037618708897) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a16000, value) }
        downcasted = int96(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004a,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a20000, 1037618708898) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a26000, value) }
        downcasted = int88(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004b,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a30000, 1037618708899) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a36000, value) }
        downcasted = int80(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004c,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a40000, 1037618708900) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a46000, value) }
        downcasted = int72(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004d,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ae0000, 1037618708910) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ae0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ae0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ae6000, value) }
        downcasted = int64(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004e,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a50000, 1037618708901) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a56000, value) }
        downcasted = int56(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004f,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a60000, 1037618708902) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a66000, value) }
        downcasted = int48(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000050,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a70000, 1037618708903) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a76000, value) }
        downcasted = int40(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000051,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a80000, 1037618708904) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a86000, value) }
        downcasted = int32(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000052,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a90000, 1037618708905) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a90005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01a96000, value) }
        downcasted = int24(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000053,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01aa0000, 1037618708906) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01aa0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01aa0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01aa6000, value) }
        downcasted = int16(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000054,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ab0000, 1037618708907) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ab0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ab0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ab6000, value) }
        downcasted = int8(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000055,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ac0000, 1037618708908) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ac0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ac0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ac6000, value) }
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }

    /**
     * @dev Cast a boolean (false or true) to a uint256 (0 or 1) with no jump.
     */
    function toUint(bool b) internal pure returns (uint256 u) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ad0000, 1037618708909) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ad0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ad0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ad6000, b) }
        assembly ("memory-safe") {
            u := iszero(iszero(b))
        }
    }
}
