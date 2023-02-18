// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Interface for the PNS Guardian contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Guardian.
 * @dev All function call interfaces are defined here.
 */
interface IPNSGuardian {
	struct VerificationRecord {
		uint256 verifiedAt;
		bool isVerified;
		address owner;
	}

	function getVerificationStatus(bytes32 phoneHash) external view returns (bool);

	function getVerifiedOwner(bytes32 phoneHash) external view returns (address);

	function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory);

	function setVerificationStatus(
		bytes32 phoneHash,
		bool status,
		bytes memory _signature
	) external returns (bool);

	function setGuardianVerifier(address _guardianVerifier) external;

	function setPNSRegistry(address _registryAddress) external;
}
