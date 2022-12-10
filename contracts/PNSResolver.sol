// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


// ==========  Internal imports    ==========
import "./Interfaces/IPNSResolver.sol";
import "./Interfaces/IPNSGuardian.sol";
import "./Interfaces/IPNSRegistry.sol";



/**
 * @title The contract for phone number service.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSResolver is inherited which inherits IPNSSchema.
 */
contract PNSResolver is IPNSSchema, Initializable, AccessControlUpgradeable {

    IPNSGuardian public guardianContract;
    IPNSRegistry public registryContract;

    /// Mapping state to store resolver record
    mapping(string => ResolverRecord) resolverRecordMapping;

    /// Mapping state to store mobile phone number record that will be linked to a resolver
    mapping(bytes32 => PhoneRecord) records;


    /**
     * @dev contract initializer function. This function exist because the contract is upgradable.
     */
    function initialize(address _guardianContract, address _registryContract) external initializer {
        __AccessControl_init();
        guardianContract = IPNSGuardian(_guardianContract);
        registryContract = IPNSRegistry(_registryContract);
    }

    /**
     * @dev Returns the resolver details of the specified phoneHash.
     * @param phoneHash The specified phoneHash.
     */
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
        bool isVerified,
        uint256 expirationTime
    )
    {
        return _getRecord(phoneHash);
    }

    /**
     * @dev Returns the address that owns the specified phone number.
     * @param phoneHash The specified phoneHash.
     * @return address of the owner.
     */
    function getOwner(bytes32 phoneHash) public view virtual returns (address) {
        address addr = records[phoneHash].owner;
        if (addr == address(this)) {
            return address(0x0);
        }
        return addr;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param phoneHash The specified phoneHash.
     * @return Bool if record exists
     */
    function recordExists(bytes32 phoneHash) public view returns (bool) {
        return records[phoneHash].exists;
    }



    /**
     * @dev Returns an existing label for the specified phone number phoneHash.
     * @param phoneHash The specified phoneHash.
     */
    function getResolverDetails(bytes32 phoneHash)
    external
    view
    returns (ResolverRecord[] memory resolver)
    {
        return _getResolverDetails(phoneHash);
    }

    function getVersion() external view virtual returns (uint32) {
        return 1;
    }

    /**
     * @dev Returns the address that owns the specified phone number phoneHash.
     * @param phoneHash The specified phoneHash.
     */
    function _getRecord(bytes32 phoneHash)
    internal
    view
    returns (
        address owner,
        ResolverRecord[] memory,
        bytes32,
        uint256 createdAt,
        bool exists,
        bool isInGracePeriod,
        bool isExpired,
        bool isVerified,
        uint256 expirationTime
    )
    {
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.exists, "phone record not found");
        bool _isInGracePeriod = _hasPassedExpiryTime(phoneHash);
        bool _isExpired = _hasPassedGracePeriod(phoneHash);
        bool _isVerified = guardianContract.getVerificationStatus(phoneHash);

        return (
        recordData.owner,
        recordData.wallet,
        recordData.phoneHash,
        recordData.createdAt,
        recordData.exists,
        _isInGracePeriod,
        _isExpired,
        _isVerified,
        recordData.expirationTime
        );
    }


    /**
    * @dev Calculate the
     * @param phoneHash The specified phoneHash.
     * @return ResolverRecord
     */
    function _getResolverDetails(bytes32 phoneHash)
    internal
    view
    returns (ResolverRecord[] memory)
    {
        PhoneRecord memory recordData = records[phoneHash];
        require(recordData.exists, "phone record not found");
        return recordData.wallet;
    }


    /**
     * @dev Returns the expiry state of an existing phone record.
     * @param phoneHash The specified phoneHash.
     */
    function _hasPassedExpiryTime(bytes32 phoneHash)
    internal
    view
    hasExpiryOf(phoneHash)
    returns (bool)
    {
        return block.timestamp > records[phoneHash].expirationTime;
    }

    /**
     * @dev Returns the grace period state of an existing phone record.
     * @param phoneHash The specified phoneHash.
     */
    function _hasPassedGracePeriod(bytes32 phoneHash)
    internal
    view
    hasExpiryOf(phoneHash)
    returns (bool)
    {
        uint256 gracePeriod = registryContract.getGracePeriod();
        return
        block.timestamp > (records[phoneHash].expirationTime + gracePeriod);
    }


    /**
     * @dev Permits the function to run only if expiry of record is found
     * @param phoneHash The phoneHash of the record to be compared.
     */
    modifier hasExpiryOf(bytes32 phoneHash) {
        require(
            records[phoneHash].expirationTime > 0,
            "phone expiry record not found"
        );
        _;
    }

}
