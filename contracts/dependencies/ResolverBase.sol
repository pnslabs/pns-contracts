// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

abstract contract ResolverBase is ERC165 {
	function isAuthorised(bytes32 node) internal view virtual returns (bool);

	modifier authorised(bytes32 node) {
		require(isAuthorised(node));
		_;
	}

	function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
		return super.supportsInterface(interfaceID);
	}
}
