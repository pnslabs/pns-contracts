// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IPNSSchema.sol';

/**
 * @title Interface for the PNS Registry contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Registry contract.
 * @dev All function call interfaces are defined here.
 */
interface IPNSRegistry is IPNSSchema {
    function setPhoneRecord(
        bytes32 phoneHash,
        address resolver,
        string memory label
    ) external;

    function linkPhoneToWallet(
        bytes32 phoneHash,
        address resolver,
        string memory label
    ) external;

    function setOwner(bytes32 phoneHash, address owner) external;

    function renew(bytes32 phoneHash) external;

    function claimExpiredPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) external;

    function setExpiryTime(uint256 time) external;

    function getExpiryTime() external view returns (uint256);

    function getGracePeriod() external view returns (uint256);

    function setGracePeriod(uint256 time) external;

    function getVersion() external view returns (uint32 version);
}
