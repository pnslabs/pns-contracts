// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

//  ==========  External imports    ==========

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

// ==========  Internal imports    ==========
// import './PNSAddress.sol';
import './Interfaces/IPNSResolver.sol';
import './Interfaces/IPNSRegistry.sol';

/**
 * @title The contract for phone number service.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSResolver is inherited which inherits IPNSSchema.
 */

contract PNSResolver is Initializable {
	uint256 private constant COIN_TYPE_ETH = 60;

	mapping(bytes32 => mapping(uint256 => string)) _resolveAddress;

	IPNSRegistry public PNSRegistry;

	/**
	 * @dev contract initializer function. This function exist because the contract is upgradable.
	 */
	function initialize(IPNSRegistry _PNSRegistry) external initializer {
		PNSRegistry = _PNSRegistry;
	}

	/**
	 * @dev Returns the address that owns the specified phone number.
	 * @param phoneHash The specified phoneHash.
	 * @return address of the owner.
	 */
	function getOwner(bytes32 phoneHash) public view virtual returns (address) {
		IPNSRegistry.PhoneRecord memory recordData = _getRecord(phoneHash);
		return recordData.owner;
	}

	/**
	 * @dev Returns an the resolver details for the specified phone number phoneHash.
	 * @param phoneHash The specified phoneHash.
	 */
	function getResolverDetails(bytes32 phoneHash) external view returns (IPNSRegistry.ResolverRecord[] memory) {
		return PNSRegistry.getResolver(phoneHash);
	}

	function getVersion() external view virtual returns (uint32) {
		return 1;
	}

	/**
	 * @dev Returns the address that owns the specified phone number phoneHash.
	 * @param phoneHash The specified phoneHash.
	 */
	function _getRecord(bytes32 phoneHash) internal view returns (IPNSRegistry.PhoneRecord memory) {
		return PNSRegistry.getRecord(phoneHash);
	}

	function getAddress(bytes32 phoneHash, uint256 coinType) public view virtual returns (string memory) {
		return _resolveAddress[phoneHash][coinType];
	}

	/**
	 * Returns the address associated with an PNS phoneHash.
	 * @param phoneHash The PNS phoneHash to query.
	 * @return The associated address.
	 */
	function getAddress(bytes32 phoneHash) public view virtual returns (string memory) {
		return getAddress(phoneHash, COIN_TYPE_ETH);
		// bytes memory validateAddress = bytes(a);
	}

	/**
	 * Sets the address associated with an PNS phoneHash.
	 * May only be called by the owner of that phoneHash in the PNS registry.
	 * @param phoneHash The phoneHash to update.
	 * @param addr The address to set.
	 */
	function setAddress(bytes32 phoneHash, string calldata addr) external virtual {
		setAddress(phoneHash, COIN_TYPE_ETH, addr);
	}

	function setAddress(
		bytes32 phoneHash,
		uint256 coinType,
		string memory addr
	) public virtual authorised(phoneHash) {
		_resolveAddress[phoneHash][coinType] = addr;
	}

	function isAuthorised(bytes32 phoneHash) internal view returns (bool) {
		return msg.sender == getOwner(phoneHash);
	}

	modifier authorised(bytes32 phoneHash) {
		require(isAuthorised(phoneHash));
		_;
	}
}
