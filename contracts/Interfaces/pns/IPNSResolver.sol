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
	// storing expiration and creation as uint48s saves gas as calling the mapping that returns this slot only has to do 1 sloads under the hood
	// addresses are uint160s by default and so can be packed with uint96 which is (uint48 * 2)
	// this is safe to when using it as a time variable as uint48,max is the year 8,927,483 AD
	struct PhoneRecord {
		address owner;
		uint48 expiration;
		uint48 creation;
	}

	function getOwner(bytes32 phoneHash) external view returns (address);

	function getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory);

	function getVersion() external view returns (uint32 version);

	function setAddr(bytes32 phoneHash, string calldata addr) external;
}
