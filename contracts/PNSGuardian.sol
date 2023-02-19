// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './Interfaces/IPNSGuardian.sol';
import './Interfaces/IPNSRegistry.sol';

/// @title Handles the authentication of the PNS registry
/// @author  PNS core team
/// @notice The PNS Guardian is responsible for authenticating the records created in PNS registry
contract PNSGuardian is Initializable, IPNSGuardian, Ownable, EIP712Upgradeable {
	/// the guardian layer address that updates verification state
	address public registryAddress;

	IPNSRegistry public registryContract;

	address public guardianVerifier;
	// The EIP-712 typehash for the verify struct used by the contract
	bytes32 private constant _VERIFY_TYPEHASH = keccak256('Verify(bytes32 phoneHash)');

	// Mapping statte to store verification record
	mapping(bytes32 => VerificationRecord) verifiedRecord;

	/**
	 * @dev logs the event when a phone record is verified.
	 * @param owner The phoneHash to be linked to the record.
	 * @param phoneHash The resolver (address) of the record
	 * @param verifiedAt The address of the owner
	 */
	event PhoneVerified(address indexed owner, bytes32 indexed phoneHash, uint256 verifiedAt);

	/**
	 * @dev contract initializer function. This function exist because the contract is upgradable.
	 */
	function initialize(address _guardianVerifier) external initializer {
		__EIP712_init('PNS Guardian', '1.0');
		guardianVerifier = _guardianVerifier;
	}

	/**
	 * @notice updates user authentication state once authenticated
	 */
	function setVerificationStatus(
		bytes32 phoneHash,
		bool status,
		bytes calldata _signature
	) external onlyRegistryContract returns (bool) {
		bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(_VERIFY_TYPEHASH, phoneHash)));
		address signer = ECDSA.recover(digest, _signature);
		//implement 20 days to reauthicate record & claim mechanism here.
		VerificationRecord storage verificationRecord = verifiedRecord[phoneHash];

		if (verificationRecord.owner == address(0)) {
			verificationRecord.owner = signer;
			verificationRecord.verifiedAt = block.timestamp;
			verificationRecord.isVerified = true;
		}
		emit PhoneVerified(signer, phoneHash, block.timestamp);
		return verificationRecord.owner != address(0);
	}

	/**
	 * @notice updates registry layer address
	 */
	function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory) {
		VerificationRecord memory verificationRecord = verifiedRecord[phoneHash];
		return verificationRecord;
	}

	/**
	 * @notice updates registry layer address
	 */
	function getVerificationStatus(bytes32 phoneHash) external view returns (bool) {
		return verifiedRecord[phoneHash].isVerified;
	}

	/**
	 * @notice updates registry layer address
	 */
	function getVerifiedOwner(bytes32 phoneHash) external view returns (address) {
		return verifiedRecord[phoneHash].owner;
	}

	/**
	 * @notice updates registry layer address
	 */
	function setPNSRegistry(address _registryAddress) external onlyGuardianVerifier {
		registryAddress = _registryAddress;
		registryContract = IPNSRegistry(registryAddress);
	}

	/**
	 * @notice updates guardian layer address
	 */
	function setGuardianVerifier(address _guardianVerifier) external onlyGuardianVerifier {
		guardianVerifier = _guardianVerifier;
	}

	/**
	 * @dev Permits modifications only by an guardian Layer Address.
	 */
	modifier onlyRegistryContract() {
		require(msg.sender == registryAddress, 'Only Registry Contract: not allowed ');
		_;
	}

	modifier onlyGuardianVerifier() {
		require(msg.sender == guardianVerifier, 'Only Guardian Verifier');
		_;
	}
}
