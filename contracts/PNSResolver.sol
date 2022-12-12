// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

//  ==========  External imports    ==========

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

// ==========  Internal imports    ==========
import './Interfaces/IPNSResolver.sol';
import './Interfaces/IPNSRegistry.sol';

/**
 * @title The contract for phone number service.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSResolver is inherited which inherits IPNSSchema.
 */
contract PNSResolver is IPNSSchema, Initializable {
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
		PhoneRecord memory recordData = _getRecord(phoneHash);
		return recordData.owner;
	}

	/**
	 * @dev Returns whether a record has been imported to the registry.
	 * @param phoneHash The specified phoneHash.
	 * @return Bool if record exists
	 */
	function recordExists(bytes32 phoneHash) public view returns (bool) {
		PhoneRecord memory recordData = _getRecord(phoneHash);
		return recordData.exists;
	}

	/**
	 * @dev Returns an existing label for the specified phone number phoneHash.
	 * @param phoneHash The specified phoneHash.
	 */
	function getResolverDetails(bytes32 phoneHash) external view returns (ResolverRecord[] memory resolver) {
		return _getResolverDetails(phoneHash);
	}

	function getVersion() external view virtual returns (uint32) {
		return 1;
	}

	/**
	 * @dev Returns the address that owns the specified phone number phoneHash.
	 * @param phoneHash The specified phoneHash.
	 */
	function _getRecord(bytes32 phoneHash) internal view returns (PhoneRecord memory) {
		return PNSRegistry.getRecord(phoneHash);
	}

	/**
	 * @dev Calculate the
	 * @param phoneHash The specified phoneHash.
	 * @return ResolverRecord
	 */
	function _getResolverDetails(bytes32 phoneHash) internal view returns (ResolverRecord[] memory) {
		PhoneRecord memory recordData = _getRecord(phoneHash);
		require(recordData.exists, 'phone record not found');
		return recordData.wallet;
	}

	/**
	 * @dev Returns the expiry state of an existing phone record.
	 * @param phoneHash The specified phoneHash.
	 */
	function _hasPassedExpiryTime(bytes32 phoneHash) internal view hasExpiryOf(phoneHash) returns (bool) {
		PhoneRecord memory recordData = _getRecord(phoneHash);
		return block.timestamp > recordData.expirationTime;
	}

	/**
	 * @dev Returns the grace period state of an existing phone record.
	 * @param phoneHash The specified phoneHash.
	 */
	function _hasPassedGracePeriod(bytes32 phoneHash) internal view hasExpiryOf(phoneHash) returns (bool) {
		uint256 gracePeriod = PNSRegistry.getGracePeriod();
		PhoneRecord memory recordData = _getRecord(phoneHash);
		return block.timestamp > (recordData.expirationTime + gracePeriod);
	}

	/**
	 * @dev Permits the function to run only if expiry of record is found
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
	modifier hasExpiryOf(bytes32 phoneHash) {
		PhoneRecord memory recordData = _getRecord(phoneHash);
		require(recordData.expirationTime > 0, 'phone expiry record not found');
		_;
	}
}
