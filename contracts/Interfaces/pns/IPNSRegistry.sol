// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IPNSSchema.sol';

/**
 * @title Interface for the PNS Registry contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Registry contract.
 * @dev All function call interfaces are defined here.
 */
interface IPNSRegistry is IPNSSchema {
	/**
	 * @dev logs the event when a phoneHash record is created.
	 * @param phoneHash The phoneHash to be linked to the record.
	 * @param wallet The resolver (address) of the record
	 * @param owner The address of the owner
	 */
	event PhoneRecordCreated(bytes32 indexed phoneHash, string indexed wallet, address indexed owner);

	event PhoneNumberVerified(bytes32 indexed phoneHash, bool status);

	/**
	 * @dev logs when there is a transfer of ownership of a phoneHash to a new address
	 * @param phoneHash The phoneHash of the record to be updated.
	 * @param owner The address of the owner
	 */
	event Transfer(bytes32 indexed phoneHash, address indexed owner);

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
	 * @param newAddress The new expiry time in seconds.
	 */
	event changeTreasury(address indexed updater, address newAddress);

	event changeGracePeriod(address indexed updater, uint256 expiryTime);

	/**
	 * @dev logs when funds is withdrawn from the smar contracts.
	 * @param _recipient withdrawal recipient
	 * @param amount Withdeawal amount
	 *
	 */
	event WithdrawalSuccessful(address indexed _recipient, uint256 amount);

	// event Transfer(bytes32 indexed phoneHash, address owner);

	function setPhoneRecord(bytes32 phoneHash, string calldata resolver) external payable;

	function getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory);

	function renew(bytes32 phoneHash) external payable;

	// function setExpiryTime(uint256 time) external;

	// function isRecordVerified(bytes32 phoneHash) external view returns (bool);

	// function getExpiryTime() external view returns (uint256);

	// function getGracePeriod() external view returns (uint256);

	// function setGracePeriod(uint256 time) external;

	// function setRegistryCost(uint256 _registryCost) external;

	// function setRegistryRenewCost(uint256 _renewalCost) external;

	// function getRecordMapping(bytes32 phoneHash) external view returns (PhoneRecord memory);

	function withdraw(address _recipient, uint256 amount) external;

	function getVersion() external view returns (uint32 version);

	function recordExists(bytes32 phoneHash) external view returns (bool);

	// function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory);
}
