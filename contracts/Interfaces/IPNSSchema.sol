// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface to define the PNS contract schemas.
 * @author PNS foundation core
 * @notice This only serves as a schema guide for the PNS contract.
 * @dev All contract schemas are defined here.
 */
interface IPNSSchema {
	/**
	 * @dev logs the event when a phoneHash record is created.
	 * @param phoneHash The phoneHash to be linked to the record.
	 * @param wallet The resolver (address) of the record
	 * @param owner The address of the owner
	 */
	event PhoneRecordCreated(bytes32 indexed phoneHash, address indexed wallet, address indexed owner);

	/**
	 * @dev logs when there is a transfer of ownership of a phoneHash to a new address
	 * @param phoneHash The phoneHash of the record to be updated.
	 * @param owner The address of the owner
	 */
	event Transfer(bytes32 indexed phoneHash, address indexed owner);

	/**
	 * @dev logs when a resolver address is linked to a specified phoneHash.
	 * @param phoneHash The phoneHash of the record to be linked.
	 * @param wallet The address of the resolver.
	 */
	event PhoneLinked(bytes32 indexed phoneHash, address indexed wallet);

	/**
	 * @dev logs when phone record has entered a grace period.
	 * @param phoneHash The phoneHash of the record.
	 */
	event PhoneRecordEnteredGracePeriod(bytes32 indexed phoneHash);

	/**
	 * @dev logs when phone record has expired.
	 * @param phoneHash The phoneHash of the record.
	 */
	event PhoneRecordExpired(bytes32 indexed phoneHash);

	/**
	 * @dev logs when phone record is re-authenticated.
	 * @param phoneHash The phoneHash of the record.
	 */
	event PhoneRecordRenewed(bytes32 indexed phoneHash);

	/**
	 * @dev logs when phone record is claimed.
	 * @param updater Who made the call
	 * @param expiryTime The new expiry time in seconds.
	 */
	event ExpiryTimeUpdated(address indexed updater, uint256 expiryTime);

	/**
	 * @dev logs when phone record is claimed.
	 * @param updater Who made the call
	 * @param gracePeriod The new grace period in seconds.
	 *
	 */
	event GracePeriodUpdated(address indexed updater, uint256 gracePeriod);

	/**
	 * @dev logs when phone is verified.
	 * @param phoneHash Phone number that was verified
	 * @param status The verification status
	 *
	 */
	event PhoneNumberVerified(bytes32 indexed phoneHash, bool status);

	/**
	 * @dev logs when funds is withdrawn from the smar contracts.
	 * @param _recipient withdrawal recipient
	 * @param amount Withdeawal amount
	 *
	 */
	event WithdrawalSuccessful(address indexed _recipient, uint256 amount);

	struct PhoneRecord {
		address owner;
		uint256 expiration;
		uint256 creation;
	}
}
