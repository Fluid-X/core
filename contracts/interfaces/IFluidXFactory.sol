// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFluidXFactory {
    event PairCreated(
        address indexed superToken0,
        address indexed superToken1,
        address pair,
        uint256
    );

    function allPairsLength() external view returns (uint256);
    function createPair(address) external;
    function setFeeCollectorSetter(address) external;
    function feeCollector() external view returns (address);
}
