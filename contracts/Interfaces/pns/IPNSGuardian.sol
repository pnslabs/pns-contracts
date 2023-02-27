// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Interface for the PNS Guardian contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Guardian.
 * @dev All function call interfaces are defined here.
 */
interface IPNSGuardian {
	/**
	 * @dev logs the event when a phone record is verified.
	 * @param owner The phoneHash to be linked to the record.
	 * @param phoneHash The resolver (address) of the record
	 * @param verifiedAt The address of the owner
	 */
	event PhoneVerified(address indexed owner, bytes32 indexed phoneHash, uint256 verifiedAt);

	struct VerificationRecord {
		uint256 verifiedAt;
		bool isVerified;
		address owner;
	}

	function getVerificationStatus(bytes32 phoneHash) external view returns (bool);

	function getVerifiedOwner(bytes32 phoneHash) external view returns (address);

	function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory);

	function verifyPhoneHash(
		bytes32 phoneHash,
		bool status,
		bytes memory _signature
	) external returns (bool);

	function setGuardianVerifier(address _guardianVerifier) external;

	function setPNSRegistry(address _registryAddress) external;
}
