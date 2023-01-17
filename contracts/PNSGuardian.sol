// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './Interfaces/IPNSSchema.sol';
import './Interfaces/IPNSRegistry.sol';

/// @title Handles the authentication of the PNS registry
/// @author  PNS core team
/// @notice The PNS Guardian is responsible for authenticating the records created in PNS registry
contract PNSGuardian is Initializable, Ownable {
	/// the guardian layer address that updates verification state
	address public registryAddress;

	IPNSRegistry public registryContract;

	address public guardianVerifier;

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
		guardianVerifier = _guardianVerifier;
	}

	/**
	 * @dev Returns the address that owns the specified phone number phoneHash.
	 * @param phoneHash The specified phoneHash.
	 */
	function _getRecord(bytes32 phoneHash) internal view returns (IPNSRegistry.PhoneRecord memory) {
		return registryContract.getRecord(phoneHash);
	}

	/**
	 * @notice gets user verification state
	 */
	function getVerificationStatus(bytes32 phoneHash) external view returns (bool) {
		IPNSRegistry.PhoneRecord memory records = _getRecord(phoneHash);
		return records.isVerified;
	}

	/**
	 * @notice updates user authentication state once authenticated
	 */
	function setVerificationStatus(
		bytes32 phoneHash,
		bytes32 _hashedMessage,
		bool status,
		bytes memory _signature
	) public onlyRegistryContract {
		bytes memory prefix = '\x19Ethereum Signed Message:\n32';
		bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
		address signer = ECDSA.recover(prefixedHashMessage, _signature);

		IPNSRegistry.PhoneRecord memory recordData = registryContract.getRecordMapping(phoneHash);

		if (!recordData.exists) {
			recordData.owner = signer;
			recordData.phoneHash = phoneHash;
			recordData.verifiedAt = block.timestamp;
			recordData.exists = true;
			recordData.isVerified = status;
		}

		registryContract.setPhoneRecordMapping(recordData, phoneHash);
		emit PhoneVerified(signer, phoneHash, block.timestamp);
	}

	/**
	 * @notice updates registry layer address
	 */
	function setPNSRegistry(address _registryAddress) external onlyOwner {
		registryAddress = _registryAddress;
		registryContract = IPNSRegistry(registryAddress);
	}

	/**
	 * @notice updates guardian layer address
	 */
	function setGuardianVerifier(address _guardianVerifier) external onlyOwner {
		guardianVerifier = _guardianVerifier;
	}

	/**
	 * @dev Permits modifications only by an guardian Layer Address.
	 */
	modifier onlyRegistryContract() {
		require(msg.sender == registryAddress, 'Only Registry Contract: not allowed ');
		_;
	}
}
