// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ==========  External imports    ==========

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

// ==========  Internal imports    ==========
import './Interfaces/pns/IPNSResolver.sol';
import './Interfaces/pns/IPNSRegistry.sol';
//ens compactibility
import './dependencies/AddrResolver.sol';

/**
 * @title The contract for phone number service.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSResolver is inherited which inherits IPNSSchema.
 */

contract PNSResolver is Initializable, AddrResolver, OwnableUpgradeable {
	uint256 private constant COIN_TYPE_ETH = 60;
	IPNSRegistry public PNSRegistry;

	/**
	 * @dev contract initializer function. This function exist because the contract is upgradable.
	 */
	function initialize(IPNSRegistry _PNSRegistry) external initializer {
		__Ownable_init();
		PNSRegistry = _PNSRegistry;
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

	function getVersion() external view virtual returns (uint32) {
		return 1;
	}

	/**
	 * @dev Returns the address that owns the specified phone number phoneHash.
	 * @param phoneHash The specified phoneHash.
	 */
	function _getRecord(bytes32 phoneHash) internal view returns (IPNSRegistry.PhoneRecord memory) {
		return PNSRegistry.getRecord(phoneHash);
	}

	function getRecord(bytes32 phoneHash) public view returns (IPNSRegistry.PhoneRecord memory) {
		return _getRecord(phoneHash);
	}

	function setPNSRegistry(address _newRegistry) external onlyOwner {
		PNSRegistry = IPNSRegistry(_newRegistry);
	}

	function isAuthorised(bytes32 phoneHash) internal view override returns (bool) {
		return msg.sender == getOwner(phoneHash);
	}
}
