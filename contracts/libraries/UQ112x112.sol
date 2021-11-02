// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// binary fixed point numbers, from UniswapV2's UQ112x112 library
// https://en.wikipedia.org/wiki/Q_(number_format)

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode uint112 as UQ122x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    // divide UQ112x112 by uint112, returns UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
