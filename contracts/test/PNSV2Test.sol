// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import '../PNS.sol';

/**
 * @title This is just a test contract for for use in testing.
 * @author PNS foundation core
 */
contract PNSV2Test is PNS {
	function getVersion() external view virtual override returns (uint32) {
		return 2;
	}
}
