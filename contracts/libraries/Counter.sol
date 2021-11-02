// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Counter {
    struct Count {
        uint32 _value;
    }

    function current(Count storage count) internal view returns (uint256) {
        return count._value;
    }
    
    function increment(Count storage count) internal {
        count._value += 1;
    }
}
