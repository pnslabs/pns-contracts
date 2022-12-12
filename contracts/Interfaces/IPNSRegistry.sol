// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IPNSGuardian.sol';

/**
 * @title Interface for the PNS Registry contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Registry contract.
 * @dev All function call interfaces are defined here.
 */
interface IPNSRegistry is IPNSGuardian {
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

	function setPhoneRecord(
		bytes32 phoneHash,
		address resolver,
		string memory label
	) external payable;

	function linkPhoneToWallet(
		bytes32 phoneHash,
		address resolver,
		string memory label
	) external;

	function setOwner(bytes32 phoneHash, address owner) external;

	function getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory);

	function renew(bytes32 phoneHash) external payable;

	function claimExpiredPhoneRecord(
		bytes32 phoneHash,
		address owner,
		address resolver,
		string memory label
	) external payable;

	function setExpiryTime(uint256 time) external;

	function isRecordVerified(bytes32 phoneHash) external view returns (bool);

	function getExpiryTime() external view returns (uint256);

	function getGracePeriod() external view returns (uint256);

	function setGracePeriod(uint256 time) external;

	function setRegistryCost(uint256 _registryCost) external;

	function setRegistryRenewCost(uint256 _renewalCost) external;

	function verifyPhone(
		bytes32 phoneHash,
		bytes32 hashedMessage,
		bool status,
		bytes memory signature
	) external;

	function setGuardianAddress(address guardianAddress) external;

	function getPhoneVerificationStatus(bytes32 phoneHash) external view returns (bool);

	function withdraw(address _recipient, uint256 amount) external;

	function getVersion() external view returns (uint32 version);
}
