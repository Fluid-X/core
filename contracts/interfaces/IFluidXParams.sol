// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFluidXParams {
    // -----
    // EVENTS
    // -----

    /// @dev governance transferred
    /// @param from old governance
    /// @param to new governance
	event GovernanceChanged(address indexed from, address indexed to);

    /// @dev fee collector set, zero address if deactivated
    /// @param from old fee collector
    /// @param to new fee collector
	event FeeCollectorChanged(address indexed from, address indexed to);

    /// @dev liquidity fee set for all pairs
    /// @param liquidityFee amount
	event LiquidityFeeChanged(uint16 liquidityFee);

    /// @dev set reward for given pair, zero amount if deactivated
    /// @param pair pair contract address
    /// @param rewardAmount amount to be distributed on swap
	event PairRewardChanged(address indexed pair, uint256 rewardAmount);

    // -----
    // VIEW FUNCTIONS
    // -----

    /// @dev gets governance
    /// @return governance address
    function getGovernance() external view returns (address);

    /// @dev gets feeCollector
    /// @return feeCollector address
    function getFeeCollector() external view returns (address);

    /// @dev gets liquidity fee for all pairs
    /// @return fee, 1 = 0.01%
    function getLiquidityFee() external view returns (uint16);

    /// @dev get gov token reward for a given pair
    /// @param _pair pair contract address
    /// @return reward amount, distributed on swap
    function getPairReward(address _pair) external view returns (uint256);

    // -----
    // SPECIAL STATE MODIFIER
    // -----

    /// @dev see `./docs/contracts.md#Contracts##FluidXParams for more
    /// IF governance is not transferred by the timestamp set on deployment
    /// ANYONE can call this method and it will burn the governance to the zero
    /// address. This is a centralization guard.
    /// @return burned
    function burnGovernance() external returns (bool);

    // -----
    // ONLY GOVERNANCE STATE MODIFIERS
    // -----

    /// @dev transfer governance
    /// @param _to new governance
	function transferGovernance(address _to) external returns (bool);

    /// @dev set fee collector, zero address if deactivated
    /// @param _feeCollector new fee collector
	function setFeeCollector(address _feeCollector) external returns (bool);

    /// @dev set liquidity fee for all pairs
    /// @param _liquidityFee amount
	function setLiquidityFee(uint16 _liquidityFee) external returns (bool);

    /// @dev set reward for given pair, zero amount if deactivated
    /// @param _pair pair contract address
    /// @param _rewardAmount amount to be distributed on swap
	function setPairReward(address _pair, uint256 _rewardAmount)
		external
		returns (bool);
}
