// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ISuperfluid, ISuperToken, SuperAppBase, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {ISuperfluidToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import {ERC777Helper} from "@superfluid-finance/ethereum-contracts/contracts/utils/ERC777Helper.sol";

import {Counter} from "./libraries/Counter.sol";
import {IFluidX} from "./interfaces/IFluidX.sol";
import {IFluidXPair} from "./interfaces/IFluidXPair.sol";
import {FluidXFactory} from "./FluidXFactory.sol";
import {ERC777Recipient} from "./util/ERC777Recipient.sol";

// TODO Allow users to withdraw their super tokens from contract
contract FluidX is IFluidX, ERC777Recipient, SuperAppBase {
	using Counter for Counter.Count;

	ISuperfluid private host;
	IInstantDistributionAgreementV1 private ida;
	ISuperToken private govToken;
	Counter.Count private indexId;
	FluidXFactory private factory;

	mapping(address => uint32) pairIndex;
	mapping(uint32 => uint256) rewardAmount;
	mapping(uint32 => mapping(address => uint256)) stake;

	constructor(
		ISuperfluid _host,
		IInstantDistributionAgreementV1 _ida,
		ISuperToken _govToken
	) {
		require(govToken.getHost() == _host, "FluidX: HOST_MISMATCH");

		host = _host;
		ida = _ida;
		govToken = _govToken;
		uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
			SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
			SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP |
			SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
			SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP |
			SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP |
			SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
		host.registerApp(configWord);
	}

	function getPairStakeReward(address _pair) external view returns (uint256) {
		return rewardAmount[pairIndex[_pair]];
	}

	// TODO onlyGovernance
	function deployFactory(address _feeCollectorSetter)
		external
		returns (bool deployed)
	{
		factory = new FluidXFactory(_feeCollectorSetter);
		deployed = true;
	}

	// TODO onlyGovernance
	function setStakeRewards(
		address _superToken0,
		address _superToken1,
		uint256 _amount
	) external {
		address pair = factory.pairs[_superToken0][_superToken1];
		require(pair != address(0), "FluidX: PAIR_NOT_FOUND");
		uint32 _indexId = pairIndex[pair];
		// create if does not exist
		if (_indexId == 0) {
			indexId.increment(); // min indexId == 1
			_indexId = indexId.current();
			host.callAgreement(
				ida,
				abi.encodeWithSelector(
					ida.createIndex.selector,
					govToken,
					_indexId,
					new bytes(0) // ctx
				),
				new bytes(0) // userData
			);
			pairIndex[pair] = _indexId;
		}
		// set reward amount
		rewardAmount[_indexId] = amount;
		// set or removed, not both :shrug:
		if (amount > 0) emit PairRewardSet(pair, amount);
		else emit PairRewardRemoved(pair);
	}

	function distributeReward(address _pair)
		external
		returns (bool distributed)
	{
		distributed = false;
		uint32 indexId = pairIndex[_pair];
		uint256 reward = rewardAmount[index];
		if (reward > 0) {
			host.callAgreement(
				ida,
				abi.encodeWithSelector(
					ida.distribute.selector,
					govToken,
					indexId,
					reward,
					new bytes(0) // ctx
				),
				new bytes(0) // userData
			);
			distributed = true;
		}
	}

	function _tokensReceived(
		IERC777 token,
		address from,
		uint256 amount,
		bytes calldata data
	) internal override {
		address pair = abi.decode(userData, (address));
		_stakeLiquidity(from, pair, amount);
	}

	function _stakeLiquidity(
		address _staker,
		address _pair,
		uint256 _amount
	) internal returns (bool) {
		uint32 indexId = pairIndex[_pair];
		require(indexId > 0, "FluidX: INACTIVE_INDEX");
		(, , uint128 units, ) = ida.getSubscription(
			_pair,
			address(this),
			indexId,
			_staker
		);
        uint128 shares = units + uint128(amount / 2);
		host.callAgreement(
			ida,
			abi.encodeWithSelector(
				ida.updateSubscription.selector,
				govToken,
				indexId,
				_staker,
				shares,
				new bytes(0) // ctx
			),
			new bytes(0) // userData
		);
	}
}
