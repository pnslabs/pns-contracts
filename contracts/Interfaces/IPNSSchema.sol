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
        uint256 createdAt;
        string label;
        bool exists;
    }

    struct PhoneRecord {
        address owner;
        ResolverRecord[] wallet;
        bytes32 phoneHash;
        uint256 createdAt;
        bool exists;
        bool isPaused;
        bool isExpired;
    }
}
