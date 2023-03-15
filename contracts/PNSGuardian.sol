// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
// import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './Interfaces/pns/IPNSGuardian.sol';
import './Interfaces/pns/IPNSRegistry.sol';

/// @title Handles the authentication of the PNS registry
/// @author  PNS core team
/// @notice The PNS Guardian is responsible for authenticating the records created in PNS registry
contract PNSGuardian is Initializable, IPNSGuardian, EIP712Upgradeable {
	/// the guardian layer address that updates verification state
	address public registryAddress;
	/// PNS registry
	IPNSRegistry public registryContract;
	/// Address of off chain verifier
	address public guardianVerifier;
	// Mapping statte to store verification record
	mapping(bytes32 => VerificationRecord) verifiedRecord;

	// The EIP-712 typehash for the verify struct used by the contract
	bytes32 private constant _VERIFY_TYPEHASH = keccak256('Verify(bytes32 phoneHash)');

	/**
	 * @dev contract initializer function. This function exist because the contract is upgradable.
	 * @param _guardianVerifier Address to be stored as off-chain verifier
	 */
	function initialize(address _guardianVerifier) external initializer {
		// __Ownable_init();
		__EIP712_init('PNS Guardian', '1.0');
		guardianVerifier = _guardianVerifier;
	}

	/**
	 * @notice Gets the verification record for a phone hash
	   @param phoneHash Hash of the phone number being verified
	   @return VerificationRecord - Verification record associated with the phone hash
	 */
	function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory) {
		VerificationRecord memory verificationRecord = verifiedRecord[phoneHash];
		return verificationRecord;
	}

	/**
	 * @notice Gets the verification status for a phone hash
	   @param phoneHash Hash of the phone number being verified
	   @return bool - Verification status associated with the phone hash
	 */
	function getVerificationStatus(bytes32 phoneHash) external view returns (bool) {
		return verifiedRecord[phoneHash].isVerified;
	}

	/**
	 * @notice Gets the verified owner for a phone hash
	   @param phoneHash Hash of the phone number being verified
	   @return address - Verified owner associated with the phone hash
	 */
	function getVerifiedOwner(bytes32 phoneHash) external view returns (address) {
		return verifiedRecord[phoneHash].owner;
	}

	/**
	 * @notice Sets the PNS registry address
	   @param _registryAddress Address of the PNS registry
	 */
	function setPNSRegistry(address _registryAddress) external onlyGuardianVerifier {
		registryContract = IPNSRegistry(_registryAddress);
	}

	/**
	 * @notice Sets the guardian verifier address
	   @param _guardianVerifier Address of the guardian verifier
	 */
	function setGuardianVerifier(address _guardianVerifier) external onlyGuardianVerifier {
		guardianVerifier = _guardianVerifier;
	}

	/**
	 * @notice Verifies a phone number hash
	   @param phoneHash Hash of the phone number being verified
	   @param status New verification status
	   @param _signature Signature provided by the off-chain verifier
	   @return bool - A boolean indicating if the verification record has been updated and is no longer a zero-address
	 */
	function verifyPhoneHash(
		bytes32 phoneHash,
		bytes32 _hashedMessage,
		bool status,
		address owner,
		bytes calldata _signature
	) external onlyGuardianVerifier returns (bool) {
		bytes memory prefix = '\x19Ethereum Signed Message:\n32';
		bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
		address signer = ECDSA.recover(prefixedHashMessage, _signature);

		require(owner == signer, 'signer does not match signature');
		VerificationRecord storage verificationRecord = verifiedRecord[phoneHash];

		if (verificationRecord.owner == address(0)) {
			verificationRecord.owner = signer;
			verificationRecord.verifiedAt = block.timestamp;
			verificationRecord.isVerified = status;
		}

		emit PhoneVerified(signer, phoneHash, block.timestamp);
		return verificationRecord.owner != address(0);
	}

	/**
	 * @dev Modifier that permits modifications only by the PNS guardian verifier.
	 */
	modifier onlyGuardianVerifier() {
		require(msg.sender == guardianVerifier, 'Only Guardian Verifier');
		_;
	}
}
