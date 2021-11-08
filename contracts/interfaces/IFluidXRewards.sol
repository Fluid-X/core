// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFluidXRewards {
	/// @dev pair reward synced to params
	/// @param pair pair to be synced
	/// @param amount total new reward amount
	event PairRewardsUpdated(address indexed pair, uint256 amount);

	/// @dev distributed rewards onSwap
	/// @param pair relevant pair
	/// @param amount amount distirbuted
	event PairRewardDistributed(address indexed pair, uint256 amount);

	/// @dev liquidity tokens staked on contract
	/// @param provider sender of liquidity tokens
	/// @param pair relevant pair
	/// @param amountStaked ONLY additional amount
	event LiquidityStaked(
		address indexed provider,
		address indexed pair,
		uint256 amountStaked
	);

	/// @dev liquidity tokens removed from stake
	/// @param provider receiver of liquidity tokens
	/// @param pair relevant pair
	/// @param amountRemoved ONLY the amount removed
	event LiquidityRemoved(
		address indexed provider,
		address indexed pair,
		uint256 amountRemoved
	);

	/// @dev sync pair rewards to params. DOES NOT update param
	/// @param _pair pair to sync
	function updatePairRewards(address _pair) external;

	/// @dev called onSwap from each pair
	/// governance MUST update param AND sync pair rewards in same call
	/// therefore, SHOULD NOT revert if does not exist
	/// @return distributed
	function distributeReward() external returns (bool);

	/// @dev stake liquidity tokens to earn IDA shares for pair rewards
	/// calls ISuperToken.transferFrom, uses the same internal _stakeLiquidity()
	/// call as the IERC777Receipient._tokensReceived() hook
	/// @param _pair relevant pair
	/// @param _amount amount to be staked, MUST APPROVE THIS CONTRACT FIRST
	/// @return staked
	function stakeLiquidity(address _pair, uint256 _amount)
		external
		returns (bool);

	/// @dev remove liquidity tokens, removes IDA shares for pair rewards
	/// calls ISuperToken.transfer() from contract to msg.sender
	/// MUST NOT revert if subscription does not exist
	/// @param _pair relevant pair
	/// @param _amount amount to remove
	/// @return removed
	function removeLiquidity(address _pair, uint256 _amount)
		external
		returns (bool);
}
