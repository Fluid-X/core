// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface INativeSuperTokenCustom {
    function intialize(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply
    ) external;
}

