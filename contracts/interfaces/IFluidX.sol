// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFluidX {
	event PairRewardSet(address indexed pair, uint256 amount);

	event PairRewardRemoved(address indexed pair);

	function getPairStakeReward(address _pair) external view returns (uint256);

	function deployFactory() external;

	function setStakeReward(
		address _superToken0,
		address _superToken1,
		uint256 _amount
	) external;

	function distributeReward(address _pair) external returns (bool);

	function stakeLiquidity(address _staker, address _pair, uint256 _amount)
		external
		returns (bool);

    function removeLiquidity(address _pair, uint256 _amount)
        external
        returns (bool);
}
