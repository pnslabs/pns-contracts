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
		address wallet;
		string label;
	}

	struct PhoneRecord {
		address owner;
		bytes32 phoneHash;
		bool exists;
		bool isVerified;
		uint256 expirationTime;
		uint256 verifiedAt;
	}
}
