// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// Straight outta Superfluid
// @superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol
import {UUPSUtils} from "../libraries/UUPSUtils.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

contract UUPSProxy is Proxy {
	function initializeProxy(address initialAddress) external {
		require(initialAddress != address(0), "UUPSProxy: ZERO_ADDRESS");
		require(
			UUPSUtils.implementation() == address(0),
			"UUPSProxy: ALREADY_INITIALIZED"
		);
		UUPSUtils.setImplementation(initialAddress);
	}

	function _implementation()
		internal
		view
		virtual
		override
		returns (address impl)
	{
		impl = UUPSUtils.implementation();
	}
}
