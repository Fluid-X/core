// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC1820Registry} from "@openzeppelin/contracts/interfaces/IERC1820Registry.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";

abstract contract ERC777Recipient is IERC777Recipient {
	IERC1820Registry internal constant REGISTRY =
		IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

	constructor() {
		REGISTRY.setInterfaceImplementer(
			address(this),
			keccak256("ERC777TokensRecipient"),
			address(this)
		);
	}

	function _tokensReceived(
		IERC777 token,
		address from,
		uint256 amount,
		bytes calldata data
	) internal virtual;

	function tokensReceived(
		address, // operator,
		address from,
		address, // to,
		uint256 amount,
		bytes calldata userData,
		bytes calldata // operatorData
	) external override {
		_tokensReceived(IERC777(msg.sender), from, amount, userData);
	}
}
