// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ISuperfluid, ISuperToken, SuperAppBase, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {ISuperfluidToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import {ERC777Helper} from "@superfluid-finance/ethereum-contracts/contracts/utils/ERC777Helper.sol";

import {Counter} from "./libraries/Counter.sol";
import {IFluidXRewards} from "./interfaces/IFluidXRewards.sol";
import {IFluidXPair} from "./interfaces/IFluidXPair.sol";
import {IFluidXParams} from "./interfaces/IFluidXParams.sol";
import {IFluidXFactory} from "./interfaces/IFluidXFactory.sol";
import {ERC777Recipient} from "./util/ERC777Recipient.sol";

// TODO Allow users to withdraw their super tokens from contract
contract FluidXRewards is IFluidXRewards, ERC777Recipient, SuperAppBase {
	using Counter for Counter.Count;

	ISuperfluid private host;
	IInstantDistributionAgreementV1 private ida;
	ISuperToken private govToken;
	IFluidXParams private params;
	IFluidXFactory private factory;

	Counter.Count private indexId;

	mapping(address => uint32) pairIndex;
	mapping(uint32 => mapping(address => uint256)) stake;

	constructor(
		ISuperfluid _host,
		IInstantDistributionAgreementV1 _ida,
		ISuperToken _govToken,
		IFluidXParams _params,
		IFluidXFactory _factory
	) {
		require(govToken.getHost() == _host, "FluidX: HOST_MISMATCH");

		host = _host;
		ida = _ida;
		govToken = _govToken;
		params = _params;
		factory = _factory;

		uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
			SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
			SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP |
			SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
			SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP |
			SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP |
			SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
		host.registerApp(configWord);
	}

	function updatePairRewards(address _pair) external override returns (bool) {
		return _updatePairRewards(_pair);
	}

	function distributeReward() external returns (bool distributed) {
		// pair contract should be msg.sender
		// distribution only calls if governance has authorized
		// host check should be sufficient
		require(
			IFluidXPair(msg.sender).getHost() == host,
			"FluidXRewards: HOST_MISMATCH"
		);
		return _distributeReward(msg.sender);
	}

	function stakeLiquidity(address _pair, uint256 _amount)
		external
		override
		returns (bool)
	{
		require(
			ISuperToken(_pair).transferFrom(msg.sender, address(this), _amount),
			"FluidX: TRANSFER_FROM"
		);
		_stakeLiquidity(msg.sender, _pair, _amount);
	}

	function removeLiquidity(address _pair, uint256 _amount) external {
		require(
			ISuperToken(_pair).transfer(msg.sender, _amount),
			"FluidX: WITHDRAWAL"
		);
		_removeLiquidity(msg.sender, _pair, _amount);
	}

	function _tokensReceived(
		IERC777 _token,
		address _from,
		uint256 _amount,
		bytes calldata _data
	) internal override {
		address pair = abi.decode(_data, (address));
		_stakeLiquidity(_from, _pair, _amount);
	}

	function _updatePairRewards(address _pair) internal returns (bool updated) {
		uint256 pairReward = params.getPairReward(_pair);
		bool exists = pairIndex[pair] > 0;
		if (!exists) {
			indexId.increment();
			uint32 pairIndexId = indexId.current();
			host.callAgreement(
				ida,
				abi.encodeWithSelector(
					ida.createIndex.selector,
					govToken,
					pairIndexId,
					new bytes(0) // ctx
				),
				new bytes(0) // userData
			);
			pairIndex[_pair] = pairReward;
			emit PairRewardsUpdated(_pair, pairReward);
			updated = true;
		}
	}

	function _distributeReward(address _pair)
		internal
		returns (bool distributed)
	{
		distributed = false;
		uint256 pairReward = params.getPairReward(_pair);
		if (pairReward > 0) {
			host.callAgreement(
				ida,
				abi.encodeWithSelector(
					ida.distribute.selector,
					govToken,
					pairIndex[_pair],
					pairReward,
					new bytes(0) // ctx
				),
				new bytes(0) // userData
			);
			emit PairRewardDistributed(_pair, pairReward);
			distributed = true;
		}
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
		emit LiquidityStaked(_staker, _pair, _amount);
	}

	function _removeLiquidity(
		address _staker,
		address _pair,
		uint256 _amount
	) internal returns (bool) {
		uint32 indexId = pairIndex[_pair];
		if (indexId > 0) {
			(bool exists, , uint128 units, ) = ida.getSubscription(
				_pair,
				address(this),
				indexId,
				_staker
			);
			// this `if` is critical. If this reverts, so does the transfer call
			// meaning if someone manages to send funds to the contract without
			// the subscription being created, their funds will be lost.
			if (exists) {
				uint128 shares = units - uint128(amount / 2);
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
				// only emit if exists, because if it does not exist, it's not
				// updating the 'stake' and is probably an emergency withdrawal
				emit LiquidityRemoved(_staker, _pair, _amount);
			}
		}
	}
}
