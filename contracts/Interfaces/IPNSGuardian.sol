// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IPNSSchema.sol';

/**
 * @title Interface for the PNS Guardian contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Guardian.
 * @dev All function call interfaces are defined here.
 */
interface IPNSGuardian is IPNSSchema {
	function setVerificationStatus(
		bytes32 phoneHash,
		bytes32 _hashedMessage,
		bool status,
		bytes memory _signature
	) external;

	function setGuardianVerifier(address _guardianVerifier) external;

	function setPNSRegistry(address _registryAddress) external;

	function getVerificationStatus(bytes32 phoneHash) external view returns (bool);

	function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory);
}
