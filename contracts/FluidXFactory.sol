// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ISuperfluid, ISuperToken, SuperAppBase, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import {IFluidXFactory} from "./interfaces/IFluidXFactory.sol";
import {IFluidXPair} from "./interfaces/IFluidXPair.sol";
import {FluidXPair} from "./FluidXPair.sol";

contract FluidXFactory is IFluidXFactory {
	address public fluidX;
	address public feeCollector;
	mapping(address => mapping(address => address)) public pairs;
	address[] public allPairs;

	constructor() {
		fluidX = msg.sender;
	}

	function allPairsLength() external view returns (uint256) {
		return allPairs.length;
	}

	function createPair(address _superToken0, address _superToken1)
		external
		returns (address pair)
	{
		require(_superToken0 != _superToken1, "FluidX: IDENTICAL_ADDRESSES");
		(address superToken0, address superToken1) = _superToken0 < _superToken1
			? (_superToken0, _superToken1)
			: (_superToken1, _superToken0);
		require(superToken0 != address(0), "FluidX: ZERO_ADDRESS");
		require(
			pairs[superToken0][superToken1] == address(0),
			"FluidX: PAIR_EXISTS"
		);
		require(
			ISuperfluidToken(superToken0).getHost() ==
				ISuperfluidToken(superToken1).getHost(),
			"FluidX: HOST_MISMATCH"
		);
		bytes memory bytecode = type(FluidXPair).creationCode;
		bytes32 salt = keccak256(abi.encodePacked(superToken0, superToken1));
		assembly {
			pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
		}
		IFluidXPair(pair).initializePair(
			fluidX,
			ISuperToken(superToken0),
			ISuperToken(superToken1)
		);
		pairs[superToken0][superToken1] = pair;
		pairs[superToken1][superToken0] = pair;
		emit PairCreated(superToken0, superToken1, pair, allPairs.push(pair));
	}

	function setFeeCollector(address _feeCollector) external {
		require(msg.sender == fluidX, "FluidX: FORBIDDEN");
		feeCollector = _feeCollector;
	}
}
