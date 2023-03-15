// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IPNSSchema.sol';
import '../profiles/IAddressResolver.sol';

/**
 * @title Interface for the PNS Resolver contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Resolver contract.
 * @dev All function call interfaces are defined here.
 */
interface IPNSResolver is IAddressResolver {
	struct PhoneRecord {
		address owner;
		uint256 expiration;
		uint256 creation;
	}

	function getOwner(bytes32 phoneHash) external view returns (address);

	function getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory);

	function getVersion() external view returns (uint32 version);

	function setAddr(bytes32 phoneHash, address addr) external;

	function seedResolver(bytes32 phoneHash, address addr) external;
}
