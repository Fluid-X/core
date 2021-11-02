// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// copied from Superfluid's with updated version
// @superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSUtils.sol
library UUPSUtils {
	bytes32 internal constant _IMPLEMENTATION_SLOT =
		0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	function implementation() internal view returns (address impl) {
		assembly {
			impl := sload(_IMPLEMENTATION_SLOT)
		}
	}

	function setImplementation(address codeAddress) internal {
		assembly {
			sstore(_IMPLEMENTATION_SLOT, codeAddress)
		}
	}
}
