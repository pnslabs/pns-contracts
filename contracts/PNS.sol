// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


// ==========  Internal imports    ==========
import "./Interfaces/IPNS.sol";
import "./PriceOracle.sol";


/**
 * @title The contract for phone number service.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNS is inherited which inherits IPNSSchema.
 */
contract PNS is IPNS, Initializable, PriceOracle, AccessControlUpgradeable{

    /// Expiry time value
    uint256 public expiryTime;
    /// Grace period value
    uint256 public gracePeriod;
    /// registry cost 
    uint256 public registryCost;
    /// registry renew cost
    uint256 public registryRenewCost;

    /// the guardian layer address that updates verification state
    address public guardianVerifier;

    /// Create a new role identifier for the minter role
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    /// Mapping state to store resolver record
    mapping(string => ResolverRecord) resolverRecordMapping;

    /// Mapping state to store mobile phone number record that will be linked to a resolver
    mapping(bytes32 => PhoneRecord) records;

  
    /**
     * @dev logs the event when a phoneHash record is created.
     * @param phoneHash The phoneHash to be linked to the record.
     * @param wallet The resolver (address) of the record
     * @param owner The address of the owner
     */
    event PhoneRecordCreated(bytes32 indexed phoneHash, address indexed wallet, address indexed owner);

    /**
     * @dev logs when there is a transfer of ownership of a phoneHash to a new address
     * @param phoneHash The phoneHash of the record to be updated.
     * @param owner The address of the owner
     */
    event Transfer(bytes32 indexed phoneHash, address indexed owner);

    /**
     * @dev logs when a resolver address is linked to a specified phoneHash.
     * @param phoneHash The phoneHash of the record to be linked.
     * @param wallet The address of the resolver.
     */
    event PhoneLinked(bytes32 indexed phoneHash, address indexed  wallet);

    /**
     * @dev logs when phone record has entered a grace period.
     * @param phoneHash The phoneHash of the record.
     */
    event PhoneRecordEnteredGracePeriod(bytes32 indexed phoneHash);

    /**
     * @dev logs when phone record has expired.
     * @param phoneHash The phoneHash of the record.
     */
    event PhoneRecordExpired(bytes32 indexed phoneHash);

    /**
     * @dev logs when phone record is re-authenticated.
     * @param phoneHash The phoneHash of the record.
     */
    event PhoneRecordAuthenticated(bytes32 indexed phoneHash);

    /**
     * @dev logs when phone record is claimed.
     * @param updater Who made the call
     * @param expiryTime The new expiry time in seconds.
     */
    event ExpiryTimeUpdated(address indexed updater, uint256 expiryTime);

    /**
     * @dev logs when phone record is claimed.
     * @param updater Who made the call
     * @param gracePeriod The new grace period in seconds.
     *
     */
    event GracePeriodUpdated( address indexed updater, uint256 gracePeriod);

    /**
     * @dev contract initializer function. This function exist because the contract is upgradable.
     */
    function initialize() external initializer {
		__AccessControl_init();
        
        //set oracle constant
        expiryTime = 365 days;
        gracePeriod = 60 days;
        registryCost = 2;  //registry cost $2 
        registryRenewCost = 3;  //registry cost $1 

        guardianVerifier = msg.sender;
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sets the record for a phoneHash.
     * @param phoneHash The phoneHash to update.
     * @param owner The address of the new owner.
     * @param resolver The address the phone number resolves to.
     * @param label The specified label of the resolver.
     */
    function setPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) external virtual {
        return _setPhoneRecord(phoneHash, owner, resolver, label);
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

    function isRecordVerified(bytes32 phoneHash) public view returns (bool) {
        return records[phoneHash].isVerified;
    }


    /**
     * @dev Transfers ownership of a phoneHash to a new address. May only be called by the current owner of the phoneHash.
     * @param phoneHash The phoneHash to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 phoneHash, address owner)
        public
        virtual
        authorised(phoneHash)
        expired(phoneHash)
        authenticated(phoneHash)
    {
        _setOwner(phoneHash, owner);
        emit Transfer(phoneHash, owner);
    }

    /**
     * @dev Sets the resolver address for the specified phoneHash.
     * @param phoneHash The phoneHash to update.
     * @param resolver The address of the resolver.
     * @param label The specified label of the resolver.
     */
    function linkPhoneToWallet(
        bytes32 phoneHash,
        address resolver,
        string memory label
    )
        public
        virtual
        authorised(phoneHash)
        expired(phoneHash)
        authenticated(phoneHash)
    {
        _linkphoneHashToWallet(phoneHash, resolver, label);
        emit PhoneLinked(phoneHash, resolver);
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

    /**
     * @dev Re authenticates a phone record.
     * @param phoneHash The phoneHash.
     */
    function reAuthenticate(bytes32 phoneHash)
        external
        virtual
        authorised(phoneHash)
        hasExpiryOf(phoneHash)
    {
        PhoneRecord storage recordData = records[phoneHash];
        bool _timeHasPassedExpiryTime = _hasPassedExpiryTime(phoneHash);
        bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);
        require(
            recordData.exists,
            "only an existing phone record can be re-authenticated"
        );
        require(
            _timeHasPassedExpiryTime && !_hasExhaustedGracePeriod,
            "only a phone record currently in grace period can be re-authenticated"
        );

        recordData.isInGracePeriod = false;
        recordData.isExpired = false;
        recordData.expirationTime = block.timestamp + expiryTime;

        emit PhoneRecordAuthenticated(phoneHash);
    }

    /**
     * @dev Claims an already existing but expired phone record, and sets a completely new resolver.
     * @param phoneHash The phoneHash.
     * @param owner The address of the new owner.
     * @param resolver The address the phone number resolves to.
     * @param label The specified label of the resolver.
     */
    function claimExpiredPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) external virtual hasExpiryOf(phoneHash) {
        PhoneRecord storage recordData = records[phoneHash];
        bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);

        require(
            recordData.exists,
            "only an existing phone record can be claimed"
        );
        require(
            _hasExhaustedGracePeriod,
            "only an expired phone record can be claimed"
        );

        delete records[phoneHash];

        return _setPhoneRecord(phoneHash, owner, resolver, label);
    }

    /**
     * @notice updates user athentication state once authenticated
     */
    function setVerificationStatus(bytes32 phoneHash, bool status)
        public
        onlyGuardianVerifier
    {
        records[phoneHash].isVerified = status;
    }


    /**
     * @dev Gets the current version of the smart contract.
     * @return uint32 The current version
     */
    function getVersion() external view virtual returns (uint32) {
        return 1;
    }

    function _setOwner(bytes32 phoneHash, address owner)
        internal
        virtual
        returns (bytes32)
    {
        records[phoneHash].owner = owner;
        return phoneHash;
    }

    //TODO: update doc
    function setRegistryCost(uint256 newCost) external onlySystemRoles
    {
      registryCost = newCost;
    }

    function setRegistryRenewCost(uint256 newRenewCost) external onlySystemRoles
    {
      registryRenewCost = newRenewCost;
    }


	/**
     * @dev Updates the expiry time of a phone record.
     * @param time The new expiry time in seconds.
     */
    function setExpiryTime(uint256 time) external  onlySystemRoles {
        expiryTime = time;
        emit ExpiryTimeUpdated(msg.sender, time);
    }

    /**
     * @dev Updates the grace period.
     * @param time The new grace period in seconds.
     */
    function setGracePeriod(uint256 time) external onlySystemRoles  {
        gracePeriod = time;
        emit GracePeriodUpdated(msg.sender, time);
    }
    
    /**
     * @notice updates guardian layer address
     */
    function setGuardianVerifier(address _guardianVerifier)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        guardianVerifier = _guardianVerifier;
    }

    function _setPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) internal {
        PhoneRecord storage recordData = records[phoneHash];
        require(!recordData.exists, "phone record already exists");

        ResolverRecord storage resolverRecordData = resolverRecordMapping[
            label
        ];

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;
        }
        recordData.phoneHash = phoneHash;
        recordData.owner = owner;
        recordData.createdAt = block.timestamp;
        recordData.exists = true;
        recordData.isInGracePeriod = false;
        recordData.isExpired = false;
        recordData.expirationTime = block.timestamp + expiryTime;
        recordData.wallet.push(resolverRecordData);

        emit PhoneRecordCreated(phoneHash, resolver, owner);
    }

    function _linkphoneHashToWallet(
        bytes32 phoneHash,
        address resolver,
        string memory label
    ) internal {
        ResolverRecord storage resolverRecordData = resolverRecordMapping[
            label
        ];
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.exists, "phone record not found");
        require(!resolverRecordData.exists, "resolver label already exist");

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;

            recordData.wallet.push(resolverRecordData);
        }
    }

    /**
     * @dev Returns the hash for a given phoneHash
     * @param phoneHash The phoneHash to hash
     * @return The ENS node hash.
     */
    function _hash(bytes32 phoneHash) internal pure returns (bytes32) {
        return keccak256(abi.encode(phoneHash));
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
            uint256 expirationTime
        )
    {
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.exists, "phone record not found");
        bool _isInGracePeriod = _hasPassedExpiryTime(phoneHash);
        bool _isExpired = _hasPassedGracePeriod(phoneHash);

        return (
            recordData.owner,
            recordData.wallet,
            recordData.phoneHash,
            recordData.createdAt,
            recordData.exists,
            _isInGracePeriod,
            _isExpired,
            recordData.expirationTime
        );
    }


    //TODO: Complete
    /**
     * @dev Returns an existing resolver for the specified phone number phoneHash.
     * @param usdAmount The specified phoneHash.
     * @return uint
     */
    function getUSDinETH(uint256 usdAmount)
        internal
        view
        returns (uint256)
    {
        
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
        return
            block.timestamp > (records[phoneHash].expirationTime + gracePeriod);
    }

    //============MODIFIERS==============
    /**
     * @dev Permits modifications only by the owner of the specified phoneHash.
     * @param phoneHash The phoneHash of the record owner to be compared.
     */
    modifier authorised(bytes32 phoneHash) {
        address owner = records[phoneHash].owner;
        require(owner == msg.sender, "caller is not authorised");
        _;
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

    /**
     * @dev Permits the function to run only if phone record is not expired.
     * @param phoneHash The phoneHash of the record to be compared.
     */
    modifier expired(bytes32 phoneHash) {
        bool _hasExpired = _hasPassedExpiryTime(phoneHash);
        if (_hasExpired) {
            PhoneRecord storage recordData = records[phoneHash];
            recordData.isInGracePeriod = true;
            emit PhoneRecordEnteredGracePeriod(phoneHash);
        }
        _;
    }

    /**
     * @dev Permits the function to run only if phone record is still authenticated.
     * @param phoneHash The phoneHash of the record to be compared.
     */
    modifier authenticated(bytes32 phoneHash) {
        bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);
        if (_hasExhaustedGracePeriod) {
            PhoneRecord storage recordData = records[phoneHash];
            recordData.isInGracePeriod = false;
            recordData.isExpired = true;
            emit PhoneRecordExpired(phoneHash);
            revert("phone record has expired, please re-authenticate");
        }
        _;
    }

    /**
     * @dev Permits modifications only by an guardian Layer Address.
     */
    modifier onlyGuardianVerifier() {
        require(msg.sender == guardianVerifier, "onlyGuardianVerifier: ");
        _;
    }

	modifier onlySystemRoles(){
		 require(hasRole(MAINTAINER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not allowed to execute function.");
		_;
	}

}
