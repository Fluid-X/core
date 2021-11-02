// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {INativeSuperTokenCustom} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/INativeSuperToken.sol";
import {CustomSuperTokenBase} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSProxy} from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";

import {IFluidXPair} from "./interfaces/IFluidXPair.sol";
import {IFluidXFactory} from "./interfaces/IFluidXFactory.sol";
import {IFluidXCallee} from "./interfaces/IFluidXCallee.sol";
import {IFluidX} from "./interfaces/IFluidX.sol";
import {Math} from "./libraries/Math.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";

contract FluidXPair is
	IFluidXPair,
	INativeSuperTokenCustom,
	CustomSuperTokenBase,
	UUPSProxy
{
	using UQ112x112 for uint224;

	string public constant _name = "FluidX LP";
	string public constant _symbol = "FLPx";

	uint256 public constant MINIMUM_LIQUIDITY = 1000;
	bytes4 private constant TRANSFER_SELECTOR =
		bytes4(keccak256(bytes("transfer(address,uint256")));

	address public fluidX;
	address public factory;
	ISuperToken public superToken0;
	ISuperToken public superToken1;
	uint112 private reserve0;
	uint112 private reserve1;
	uint32 private blockTimestampLast;
	uint256 public price0CumulativeLast;
	uint256 public price1CumulativeLast;
	uint256 public kLast;
	uint256 private unlocked = 1;

	// Reentrancy Guard
	modifier lock() {
		require(unlocked == 1, "FluidX: LOCKED");
		unlocked = 0;
		_;
		unlockeed = 1;
	}

	event Sync(uint112 reserve0, uint112 reserve1);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to,
		bool rewardDistributed
	);

	constructor() {
		factory = msg.sender;
	}

	// Pair Initialization
	function initializePair(address _fluidX, ISuperToken _superToken0, ISuperToken _superToken1)
		public
	{
		fluidX = _fluidX;
		// SuperToken should be validated by the factory!!!
		require(msg.sender == factory, "FluidX: FORBIDDEN");
		superToken0 = _superToken0;
		superToken1 = _superToken1;
		// INativeSuperToken.initialize
		initialize(_name, _symbol, 0);
	}

	function getReserves()
		public
		view
		returns (
			uint112 _reserve0,
			uint112 _reserve1,
			uint32 _blockTimestampLast
		)
	{
		_reserve0 = reserve0;
		_reserve1 = reserve1;
		_blockTimestampLast = blockTimestampLast;
	}

	function mint(address to) external lock returns (uint256 liquidity) {
		(uint112 _reserve0, uint112 _reserve1, ) = getReserves();
		uint256 balance0 = superToken0.balanceOf(address(this));
		uint256 balance1 = superToken1.balanceOf(address(this));
		uint256 amount0 = balance0 - _reserve0;
		uint256 amount1 = balance1 - _reserve1;
		bool feeOn = _mintFee(_reserve0, _reserve1);
		uint256 _totalSupply = totalSupply;
		if (_totalSupply == 0) {
			liquidity = Math.sqrt((amount0 * amount1) - MINIMUM_LIQUIDITY);
			_mint(address(0), MINIMUM_LIQUIDITY);
		} else {
			uint256 liquidity0 = (amount0 * _totalSupply) / _reserve0;
			uint256 liquidity1 = (amount1 * _totalSupply) / _reserve1;
			liquidity = Math.min(liquidity0, liquidity1);
		}
		require(liqudity > 0, "FluidX: INSUFFICIENT_MINT");
		_mint(to, liquidity);
		_update(balance0, balance1, _reserve0, _reserve1);
		if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
		emit Mint(msg.sender, amount0, amount1);
	}

	function burn(address to)
		external
		lock
		returns (uint256 amount0, uint256 amount1)
	{
		// gas savings
		(uint112 _reserve0, uint112 _reserve1, ) = getReserves();
		ISuperToken _superToken0 = superToken0;
		ISuperToken _superToken1 = superToken1;

		uint256 balance0 = _superToken0.balanceOf(address(this));
		uint256 balance1 = _superToken1.balanceOf(address(this));
		uint256 liquidity = balances[address(this)];
		bool feeOn = _mintFee(_reserve0, _reserve1);
		uint256 _totalSupply = totalSupply; // gas savings
		amount0 = (liquidity * balance0) / _totalSupply;
		amount1 = (liqidity * balance1) / _totalSupply;
		require(amount0 > 0 && amount1 > 0, "FluidX: INSUFFICIENT_BURN");
		_burn(address(this), liquidity);
		_superToken0.transfer(to, amount0);
		_superToken1.transfer(to, amount1);
		balance0 = _superToken0.balanceOf(address(this));
		balance1 = _superToken1.balanceOf(address(this));
		_update(balance0, balance1, _reserve0, _reserve1);
		if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
		emit Burn(msg.sender, amount0, amount1, to);
	}

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external lock {
		require(
			amount0Out > 0 || amount1Out > 0,
			"FluidX: INSUFFICIENT_OUTPUT"
		);
		(uint112 _reserve0, uint112 _reserve1, ) = getReserves();
		require(
			amount0Out < _reserve0 && amount1Out < _reserve1,
			"FluidX: INSUFFICIENT_LIQUIDITY"
		);
		uint256 balance0;
		uint256 balance1;
		{
			// scope for _superToken{0,1}, avoids stack too deep errors
			ISuperToken _superToken0 = superToken0;
			ISuperToken _superToken1 = superToken1;
			require(
				to != _superToken0 && to != _superToken1,
				"FluidX: INVALID_TO"
			);
			if (amount0Out > 0) _superToken0.transfer(to, amount0Out);
			if (amount1Out > 0) _superToken1.transfer(to, amount1Out);
			if (data.length > 0)
				IFluidXCallee(to).fluidXCall(
					msg.sender,
					amount0Out,
					amount1Out,
					data
				);
			balance0 = _superToken0.balanceOf(address(this));
			balance1 = _superToken1.balanceOf(address(this));
		}
		uint256 amount0In = balance0 > _reserve0 - amount0Out
			? balance0 - (_reserve0 - amount0Out)
			: 0;
		uint256 amount1In = balance1 > _reserve1 - amount1Out
			? balance1 - (_reserve1 - amount1Out)
			: 0;
		require(amount0In > 0 || amount1In > 0, "FluidX: INSUFFICIENT_INPUT");
		{
			// scope for reserve{0,1}Adjusted, avoids stack too deep errors
			uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
			uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
			require(
				balance0Adjusted * balance1Adjusted >=
					uint256(_reserve0) * uint256(_reserve1) * (1000**2),
				"FluidX: K"
			);
		}
		_update(balance0, balance1, _reserve0, _reserve1);
		bool distributed = _onSwap();
		emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to, distributed);
	}

	function skim(address to) external lock {
		ISuperToken _superToken0 = superToken0;
		ISuperToken _superToken1 = superToken1;
		uint256 amount0 = _superToken0.balanceOf(address(this)) - reserve0;
		uint256 amount1 = _superToken1.balanceOf(address(this)) - reserve1;
		_superToken0.transfer(to, amount0);
		_superToken1.transfer(to, amount1);
	}

	function sync() external lock {
		uint256 balance0 = superToken0.balanceOf(address(this));
		uint256 balance1 = superToken1.balanceOf(address(this));
		_update(balance0, balance1, reserve0, reserve1);
	}

	function _update(
		uint256 balance0,
		uint256 balance1,
		uint112 _reserve0,
		uint112 _reserve1
	) private {
		require(
			balance0 <= uint112(-1) && balance1 <= uint112(-1),
			"FluidX: OVERFLOW"
		);
		uint32 blockTimestamp = uint32(block.timestamp % 2**32);
		uint32 timeElapsed = blockTimestamp - blockTimestampLast;
		if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
			// + Overflow Desired
			unchecked {
				price0CumulativeLast +=
					uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
					timeElapsed;
				price1CumulativeLast +=
					uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
					timeElapsed;
			}
			reserve0 = uint112(balance0);
			reserve1 = uint112(balance1);
			blockTimestampLast = blockTimestamp;
			emit Sync(reserve0, reserve1);
		}
	}

	function _mintFee(uint112 _reserve0, uint112 _reserve1)
		private
		returns (bool feeOn)
	{
		address feeCollector = IFluidXFactory(factory).feeCollector();
		feeOn = feeCollector != address(0);
		uint256 _kLast = kLast; // gas savings
		if (feeOn) {
			if (_kLast != 0) {
				uint256 rootK = Math.sqrt(uint256(_reserve0 * _reserve1));
				uint256 rootKLast = Math.sqrt(_kLast);
				if (rootK > rootKLast) {
					uint256 numerator = totalSupply * (rootK - rootKLast);
					uint256 denominator = rootK * 5 + rootKLast;
					uint256 liquidity = numerator / denominator;
					if (liquidity > 0) _mint(feeCollector, liquidity);
				}
			}
		} else if (_kLast != 0) {
			kLast = 0;
		}
	}

	function _onSwap() internal returns (bool distributed) {
		distributed = IFluidX(fluidX).distributeReward(address(this));
	}
}
