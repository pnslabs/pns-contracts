// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "./IPNSSchema.sol";

/**
 * @title Interface for the PNS contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS contract.
 * @dev All function call interfaces are defined here.
 */
interface IPNS is IPNSSchema {
    function setPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) external;

    function linkPhoneToWallet(
        bytes32 phoneHash,
        address resolver,
        string memory label
    ) external;

    function setOwner(bytes32 phoneHash, address owner) external;

    function recordExists(bytes32 phoneHash) external view returns (bool);

    function getOwner(bytes32 phoneHash) external view returns (address);

    function getRecord(bytes32 phoneHash)
        external
        view
        returns (
            address owner,
            ResolverRecord[] memory,
            bytes32,
            uint256 createdAt,
            bool exists,
            bool isInGracePeriod,
            bool isExpired,
            uint256 expirataionTime
        );

    function getResolverDetails(bytes32 phoneHash)
        external
        view
        returns (ResolverRecord[] memory);

    function reAuthenticate(bytes32 phoneHash) external;

    function claimExpiredPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) external;

    function setNewExpiryTime(uint256 time) external;

    function setNewGracePeriod(uint256 time) external;

    function getExpiryTime() external view returns (uint256);

    function getGracePeriod() external view returns (uint256);

    function addAdmin(address newAdmin) external;

    function getAdmin(address admin)
        external
        view
        returns (
            address user,
            uint256 createdAt,
            bool exists
        );
}
