// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import '../Interfaces/profiles/IAddrResolver.sol';
import '../Interfaces/profiles/IAddressResolver.sol';
import './ResolverBase.sol';
import 'hardhat/console.sol';

abstract contract AddressResolver is IAddrResolver, IAddressResolver, ResolverBase {
	uint256 internal constant COIN_TYPE_ETH = 60;
	mapping(bytes32 => mapping(uint256 => bytes)) resolveAddress;

	/**
	 * Sets the address associated with an PNS phoneHash.
	 * May only be called by the owner of that phoneHash in the PNS registry.
	 * @param phoneHash The phoneHash to update.
	 * @param a The address to set.
	 */
	function setAddr(bytes32 phoneHash, address a) external virtual authorised(phoneHash) {
		setAddr(phoneHash, COIN_TYPE_ETH, addressToBytes(a));
	}

	/**
	 * Returns the address associated with an PNS phoneHash.
	 * @param phoneHash The PNS phoneHash to query.
	 * @return The associated address.
	 */
	function addr(bytes32 phoneHash) public view virtual override returns (address payable) {
		bytes memory a = addr(phoneHash, COIN_TYPE_ETH);
		if (a.length == 0) {
			return payable(0);
		}
		return bytesToAddress(a);
	}

	function setAddr(
		bytes32 phoneHash,
		uint256 coinType,
		bytes memory a
	) public virtual authorised(phoneHash) {
		emit AddressChanged(phoneHash, coinType, a);
		if (coinType == COIN_TYPE_ETH) {
			emit AddrChanged(phoneHash, bytesToAddress(a));
		}
		resolveAddress[phoneHash][coinType] = a;
	}

	function addr(bytes32 phoneHash, uint256 coinType) public view virtual override returns (bytes memory) {
		return resolveAddress[phoneHash][coinType];
	}

	function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
		return
			interfaceID == type(IAddrResolver).interfaceId ||
			interfaceID == type(IAddressResolver).interfaceId ||
			super.supportsInterface(interfaceID);
	}

	function bytesToAddress(bytes memory b) internal pure returns (address payable a) {
		require(b.length == 20);
		assembly {
			a := div(mload(add(b, 32)), exp(256, 12))
		}
	}

	function addressToBytes(address a) internal pure returns (bytes memory b) {
		b = new bytes(20);
		assembly {
			mstore(add(b, 32), mul(a, exp(256, 12)))
		}
	}
}
