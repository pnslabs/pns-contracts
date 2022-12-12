// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import './Interfaces/IPNSSchema.sol';
import './Interfaces/IPNSRegistry.sol';

/// @title Handles the authentication of the PNS registry
/// @author  PNS core team
/// @notice The PNS Guardian is responsible for authenticating the records created in PNS registry
abstract contract PNSGuardian is IPNSSchema, IPNSRegistry, Initializable, AccessControlUpgradeable {
	/// the guardian layer address that updates verification state
	address public guardianVerifier;

	/// Mapping state to store mobile phone number record that will be linked to a resolver
	mapping(bytes32 => PhoneRecord) public records;

	/// Create a new role identifier for the minter role
	bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

	/**
	 * @dev logs the event when a phone record is verified.
	 * @param owner The phoneHash to be linked to the record.
	 * @param phoneHash The resolver (address) of the record
	 * @param verifiedAt The address of the owner
	 */
	event PhoneVerified(address indexed owner, bytes32 indexed phoneHash, uint256 verifiedAt);

	/**
	 * @notice updates guardian layer address
	 */
	function setGuardianVerifier(address _guardianVerifier) external onlySystemRoles {
		guardianVerifier = _guardianVerifier;
	}

	/**
	 * @notice updates user authentication state once authenticated
	 */
	function setVerificationStatus(
		bytes32 phoneHash,
		bytes32 _hashedMessage,
		bool status,
		bytes memory _signature
	) public onlyGuardianVerifier {
		bytes memory prefix = '\x19Ethereum Signed Message:\n32';
		bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
		address signer = ECDSA.recover(prefixedHashMessage, _signature);

		PhoneRecord storage recordData = records[phoneHash];
		recordData.owner = signer;
		recordData.phoneHash = phoneHash;
		recordData.verifiedAt = block.timestamp;
		recordData.exists = true;
		recordData.isVerified = status;

		emit PhoneVerified(signer, phoneHash, block.timestamp);
	}

	/**
	 * @notice gets user verification state
	 */
	function getVerificationStatus(bytes32 phoneHash) external view returns (bool) {
		return records[phoneHash].isVerified;
	}

	function _getVerificationRecord(bytes32 phoneHash) internal view returns (VerificationRecord memory) {
		PhoneRecord memory recordData = records[phoneHash];
		VerificationRecord memory verificationRecordData = VerificationRecord({
			owner: recordData.owner,
			phoneHash: recordData.phoneHash,
			verifiedAt: recordData.verifiedAt,
			exists: recordData.exists,
			isVerified: recordData.isVerified
		});
		return verificationRecordData;
	}

	/**
	 * @notice gets user verification records
	 */
	function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory) {
		return _getVerificationRecord(phoneHash);
	}

	/**
	 * @dev Permits modifications only by an guardian Layer Address.
	 */
	modifier onlyGuardianVerifier() {
		require(msg.sender == guardianVerifier, 'onlyGuardianVerifier: not allowed ');
		_;
	}

	modifier onlySystemRoles() {
		require(hasRole(MAINTAINER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not allowed to execute function');
		_;
	}
}
