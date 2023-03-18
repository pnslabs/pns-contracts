// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ==========EXTERNAL IMPORTS==========

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

// ==========INTERNAL IMPORTS==========
import './Interfaces/pns/IPNSResolver.sol';
import './Interfaces/pns/IPNSRegistry.sol';
//ens compactibility
import './dependencies/AddressResolver.sol';

/**
 * @title The contract for phone number service.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSResolver is inherited which inherits IPNSSchema.
 */

contract PNSResolver is Initializable, AddressResolver, OwnableUpgradeable {
	
	//  ==========STATE VARIABLES==========
	IPNSRegistry public PNSRegistry;

	//  ==========EXTERNAL FUNCTIONS==========

	/**
	 * @dev Initializes the contract with an instance of the IPNSRegistry contract.
	 * @param _PNSRegistry The address of the IPNSRegistry contract to use.
	 */
	function initialize(IPNSRegistry _PNSRegistry) external initializer {
		__Ownable_init();
		PNSRegistry = _PNSRegistry;
	}

	/**
	 * @dev Returns the version number of the contract.
	 * @return The version number of the contract.
	 */
	function getVersion() external view virtual returns (uint32) {
		return 1;
	}

	/**
	 * @dev Sets the address of the IPNSRegistry contract.
	 * @param _newRegistry The address of the new IPNSRegistry contract.
	 */
	function setPNSRegistry(address _newRegistry) external onlyOwner {
		PNSRegistry = IPNSRegistry(_newRegistry);
	}

	/**
	 * @dev Seeds the resolver address for the specified phone number hash and coin type.
	 * @param phoneHash The hash of the phone number to seed the resolver for.
	 * @param a The resolver address to seed.
	 */
	function seedResolver(bytes32 phoneHash, address a) external registryAuthorised(phoneHash) {
		seedAddr(phoneHash, COIN_TYPE_ETH, addressToBytes(a));
	}

	//  ==========PUBLIC FUNCTIONS==========

	/**
	 * @dev Returns the record associated with the specified phone number hash.
	 * @param phoneHash The hash of the phone number to retrieve the record for.
	 * @return The PhoneRecord associated with the specified phone number hash.
	 */
	function getRecord(bytes32 phoneHash) public view returns (IPNSRegistry.PhoneRecord memory) {
		return _getRecord(phoneHash);
	}

	/**
	 * @dev Returns the address that owns the specified phone number.
	 * @param phoneHash The specified phoneHash.
	 * @return address of the owner.
	 */
	function getOwner(bytes32 phoneHash) public view virtual returns (address) {
		IPNSRegistry.PhoneRecord memory recordData = _getRecord(phoneHash);
		return recordData.owner;
	}

	//  ==========INTERNAL FUNCTIONS==========

	/**
	 * @dev Seeds the address for the specified phone number hash and coin type.
	 * @param phoneHash The hash of the phone number to seed the address for.
	 * @param coinType The coin type to seed the address for.
	 * @param a The address to seed.
	 */
	function seedAddr(bytes32 phoneHash, uint256 coinType, bytes memory a) internal registryAuthorised(phoneHash) {
		emit AddressChanged(phoneHash, coinType, a);
		if (coinType == COIN_TYPE_ETH) {
			emit AddrChanged(phoneHash, bytesToAddress(a));
		}
		resolveAddress[phoneHash][coinType] = a;
	}

	/**
	 * @dev Checks if the message sender is authorized to modify the record associated with the specified phone number hash.
	 * @param phoneHash The hash of the phone number to check authorization for.
	 * @return True if the message sender is authorized, false otherwise.
	 */
	function isAuthorised(bytes32 phoneHash) internal view override returns (bool) {
		return msg.sender == getOwner(phoneHash);
	}

	/**
	 * @dev Returns the record associated with the specified phone number hash.
	 * @param phoneHash The hash of the phone number to retrieve the record for.
	 * @return The PhoneRecord associated with the specified phone number hash.
	 */
	function _getRecord(bytes32 phoneHash) internal view returns (IPNSRegistry.PhoneRecord memory) {
		return PNSRegistry.getRecord(phoneHash);
	}

	//  ==========MODIFIERS==========

	/**
	 * @dev Modifier to check if the message sender is authorized by the IPNSRegistry contract.
	 * @param node The node hash to check authorization for.
	 */
	modifier registryAuthorised(bytes32 node) {
		require(msg.sender == address(PNSRegistry), 'only registry can call');
		_;
	}
}
