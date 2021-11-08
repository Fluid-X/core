// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IFluidXParams} from "./interfaces/IFluidXParams.sol";

contract FluidXParams is IFluidXParams {
	/// @notice governance
	address private governance;

	/// @notice fee collector
	address private feeCollector;

	/// @notice liquidity provider fee, 1 = 0.01%
	uint16 private liquidityFee;

	/// @notice pair reward amounts
	mapping(address => uint256) private pairReward;

	/// @notice max fee, 100%
	uint16 private constant MAX_LIQUIDITY_FEE = 10_000;

	/// @notice deadline for governance transfer. If not transferred by
	/// deadline, public burnGovernance() can be called to set governance to the
	/// zero address.
	uint64 public immutable governanceTransferDeadline;

	/// @notice contract deployer. If governanceTransferDeadline is reached and
	/// burnGovernance() is called, it will check this address against the
	/// governance address. If the match, burn governance
	address public immutable deployer;

	modifier onlyGovernance() {
		require(msg.sender == governance, "FluidXParams: FORBIDDEN");
		_;
	}

	constructor(
		address _governance,
		address _feeCollector,
		uint16 _liquidityFee,
		uint64 _governanceTransferDeadline
	) {
		require(_liquidityFee < MAX_LIQUIDITY_FEE, "FluidXParams: INVALID_FEE");
		governance = _governance;
		feeCollector = _feeCollector;
		liquidityFee = _liquidityFee;
		governanceTransferDeadline = _governanceTransferDeadline;
		deployer = msg.sender;
	}

	// -----
	// VIEW FUNCTIONS
	// -----

	function getGovernance() external view override returns (address) {
		return governance;
	}

	function getFeeCollector() external view override returns (address) {
		return feeCollector;
	}

	function getLiquidityFee() external view override returns (uint16) {
		return liquidityFee;
	}

	function getPairReward(address _pair)
		external
		view
		override
		returns (uint256)
	{
		return pairReward[_pair];
	}

	// -----
	// SPECIAL STATE MODIFIER
	// -----

	// This should be sufficient. Maybe create guard against transferring to
	// another address? Will update.
	function burnGovernance() public override returns (bool) {
		require(
			block.timestamp > governanceTransferDeadline,
			"FluidXParams: INVALID_DATE"
		);
		require(
			governance == deployer,
			"FluidXParams: GOVERNANCE_ALREADY_TRANSFERRED"
		);
		_transferGovernance(deployer, address(0));
	}

	// -----
	// ONLY GOVERNANCE EXTERNAL STATE MODIFIERS
	// -----

	function transferGovernance(address _to)
		external
		override
		onlyGovernance
		returns (bool)
	{
		return _transferGovernance(msg.sender, _to);
	}

	function setFeeCollector(address _feeCollector)
		external
		override
		onlyGovernance
		returns (bool)
	{
		return _setFeeCollector(msg.sender, _feeCollector);
	}

	function setLiquidityFee(uint16 _liquidityFee)
		external
		override
		onlyGovernance
		returns (bool)
	{
		return _setLiquidityFee(_liquidityFee);
	}

	function setPairReward(address _pair, uint256 _rewardAmount)
		external
		override
		onlyGovernance
		returns (bool)
	{
		return _setPairReward(_pair, _rewardAmount);
	}

	// -----
	// INTERNAL STATE MODIFIERS
	// -----

	function _transferGovernance(address _from, address _to)
		internal
		returns (bool changed)
	{
		governance = _to;
		emit GovernanceChanged(_from, _to);
		changed = true;
	}

	function _setFeeCollector(address _from, address _to)
		internal
		returns (bool set)
	{
		feeCollector = _to;
		emit FeeCollectorChanged(_from, _to);
		set = true;
	}

	function _setLiquidityFee(uint16 _liquidityFee)
		internal
		returns (bool set)
	{
		require(_liquidityFee < MAX_LIQUIDITY_FEE, "FluidXParams: INVALID_FEE");
		liquidityFee = _liquidityFee;
		emit LiquidityFeeChanged(_liquidityFee);
		set = true;
	}

	function _setPairReward(address _pair, uint256 _rewardAmount)
		internal
		returns (bool set)
	{
		pairReward[_pair] = _rewardAmount;
		emit PairRewardChanged(_pair, _rewardAmount);
		set = true;
	}
}
