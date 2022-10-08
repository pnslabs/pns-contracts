// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./Interfaces/IPNS.sol";

/**
 * @title The contract for phone number service.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNS is inherited which inherits IPNSSchema.
 */
contract PNS is IPNS {
    /// Expiry time value
    uint256 private expiryTime = 365 days;
    /// Grace period value
    uint256 private gracePeriod = 60 days;

    /// Mapping state to store resolver record
    mapping(string => ResolverRecord) resolverRecordMapping;

    /// Mapping state to store mobile phone number record that will be linked to a resolver
    mapping(bytes32 => PhoneRecord) records;

    /// Mapping state to store addresses of admins
    mapping(address => Admin) admins;

    /**
     * @dev logs the event when a phoneHash record is created.
     * @param phoneHash The phoneHash to be linked to the record.
     * @param wallet The resolver (address) of the record
     * @param owner The address of the owner
     */
    event PhoneRecordCreated(bytes32 phoneHash, address wallet, address owner);

    /**
     * @dev logs when there is a transfer of ownership of a phoneHash to a new address
     * @param phoneHash The phoneHash of the record to be updated.
     * @param owner The address of the owner
     */
    event Transfer(bytes32 phoneHash, address owner);

    /**
     * @dev logs when a resolver address is linked to a specified phoneHash.
     * @param phoneHash The phoneHash of the record to be linked.
     * @param wallet The address of the resolver.
     */
    event PhoneLinked(bytes32 phoneHash, address wallet);

    /**
     * @dev logs when phone record has entered a grace period.
     * @param phoneHash The phoneHash of the record.
     */
    event PhoneRecordEnteredGracePeriod(bytes32 phoneHash);

    /**
     * @dev logs when phone record has expired.
     * @param phoneHash The phoneHash of the record.
     */
    event PhoneRecordExpired(bytes32 phoneHash);

    /**
     * @dev logs when phone record is re-authenticated.
     * @param phoneHash The phoneHash of the record.
     */
    event PhoneRecordAuthenticated(bytes32 phoneHash);

    /**
     * @dev logs when phone record is claimed.
     * @param phoneHash The phoneHash of the record.
     * @param owner The address of the new owner
     */
    event PhoneRecordClaimed(
        bytes32 phoneHash,
        address owner,
        bool isInGracePeriod,
        bool isExpired,
        uint256 expirationTime
    );

    /**
     * @dev logs when phone record is claimed.
     * @param expiryTime The new expiry time in seconds.
     * @param updater Who made the call
     */
    event ExpiryTimeUpdated(uint256 expiryTime, address updater);

    /**
     * @dev logs when phone record is claimed.
     * @param gracePeriod The new grace period in seconds.
     * @param updater Who made the call
     */
    event GracePeriodUpdated(uint256 gracePeriod, address updater);

    /**
     * @dev logs when a new admin has been added.
     * @param newAdmin The new admin address.
     * @param admin The admin who made the call.
     */
    event AdminAdded(address newAdmin, address admin);

    constructor() {
        admins[msg.sender] = Admin(msg.sender, block.timestamp, true);
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

    /**
     * @dev Transfers ownership of a phoneHash to a new address. May only be called by the current owner of the phoneHash.
     * @param phoneHash The phoneHash to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 phoneHash, address owner)
        public
        virtual
        authorised(phoneHash)
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
        require(
            recordData.exists,
            "only an existing phone record can be re-authenticated"
        );
        require(
            recordData.isInGracePeriod,
            "only a phone record in grace period can be re-authenticated"
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
        ResolverRecord storage resolverRecordData = resolverRecordMapping[
            label
        ];

        require(
            recordData.exists,
            "only an existing phone record can be claimed"
        );
        require(
            recordData.isExpired,
            "only an expired phone record can be claimed"
        );

        recordData.phoneHash = phoneHash;
        recordData.owner = owner;
        recordData.isInGracePeriod = false;
        recordData.isExpired = false;
        recordData.expirationTime = block.timestamp + expiryTime;
        delete recordData.wallet;

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;
        }

        emit PhoneRecordClaimed(
            phoneHash,
            owner,
            recordData.isInGracePeriod,
            recordData.isExpired,
            recordData.expirationTime
        );
    }

    /**
     * @dev Adds a new admin.
     * @param newAdmin The address of the new admin.
     */
    function addAdmin(address newAdmin) external isAdmin {
        require(newAdmin != address(0), "cannot add zero address as admin");
        require(!admins[newAdmin].exists, "admin already exists");

        admins[newAdmin] = Admin(newAdmin, block.timestamp, true);
        emit AdminAdded(newAdmin, msg.sender);
    }

    /**
     * @dev Gets all the current admins.
     * @param admin The address of the admin.
     * @return user admin address.
     * @return createdAt the date the admin was added.
     * @return exists if the admin exists.
     */
    function getAdmin(address admin)
        external
        view
        isAdmin
        returns (
            address user,
            uint256 createdAt,
            bool exists
        )
    {
        return (
            admins[admin].user,
            admins[admin].createdAt,
            admins[admin].exists
        );
    }

    /**
     * @dev Updates the expiry time of a phone record.
     * @param time The new expiry time in seconds.
     */
    function setNewExpiryTime(uint256 time) external isAdmin {
        expiryTime = time;
        emit ExpiryTimeUpdated(time, msg.sender);
    }

    /**
     * @dev Updates the grace period.
     * @param time The new grace period in seconds.
     */
    function setNewGracePeriod(uint256 time) external isAdmin {
        gracePeriod = time;
        emit GracePeriodUpdated(time, msg.sender);
    }

    /**
     * @dev Gets the current expiry time of a phone record.
     * @return uint256 The current expiry time in seconds.
     */
    function getExpiryTime() external view returns (uint256) {
        return expiryTime;
    }

    /**
     * @dev Gets the current grace period.
     * @return uint256 The current grace period in seconds.
     */
    function getGracePeriod() external view returns (uint256) {
        return gracePeriod;
    }

    function _setOwner(bytes32 phoneHash, address owner)
        internal
        virtual
        returns (bytes32)
    {
        records[phoneHash].owner = owner;
        return phoneHash;
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

        return (
            recordData.owner,
            recordData.wallet,
            recordData.phoneHash,
            recordData.createdAt,
            recordData.exists,
            recordData.isInGracePeriod,
            recordData.isExpired,
            recordData.expirationTime
        );
    }

    /**
     * @dev Returns an existing resolver for the specified phone number phoneHash.
     * @param phoneHash The specified phoneHash.
     */
    function _getResolverDetails(bytes32 phoneHash)
        internal
        view
        returns (ResolverRecord[] memory)
    {
        PhoneRecord storage recordData = records[phoneHash];
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
        PhoneRecord storage recordData = records[phoneHash];
        return block.timestamp > recordData.expirationTime;
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
        PhoneRecord storage recordData = records[phoneHash];
        return block.timestamp > (recordData.expirationTime + gracePeriod);
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
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.expirationTime > 0, "phone expiry record not found");
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
     * @dev Permits modifications only by an admin.
     */
    modifier isAdmin() {
        require(admins[msg.sender].exists, "caller is not an admin");
        _;
    }
}
