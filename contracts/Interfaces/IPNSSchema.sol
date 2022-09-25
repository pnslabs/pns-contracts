// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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
    }
}
