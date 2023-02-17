// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface to define the PNS contract schemas.
 * @author PNS foundation core
 * @notice This only serves as a schema guide for the PNS contract.
 * @dev All contract schemas are defined here.
 */
interface IPNSSchema {
	struct ResolverRecord {
		string wallet;
		string label;
	}

	struct PhoneRecord {
		address owner;
		bool exists;
		uint256 expiration;
		uint256 creation;
	}
}
