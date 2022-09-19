pragma solidity 0.8.9;
import "./IPNS.sol";

contract PNS {
    // assign phone number phoneHash to an address
    // transfer ownership of address to a new phone number
    // unlink phone number phoneHash to an address
    // get phone number tied to an address
    // get address tied to a phone number
    // logs when you sets the record for a phoneHash.
    event PhoneRecordCreated(bytes32 phoneHash, address wallet, address owner);

    // logs when transfers ownership of a phoneHash to a new address
    event Transfer(bytes32 phoneHash, address owner);

    //logs when a resolve address is set for the specified phoneHash.
    event PhoneLinked(bytes32 phoneHash, address wallet);

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
    mapping(string => ResolverRecord) resolverRecordMapping;
    mapping(bytes32 => PhoneRecord) records;

    // Permits modifications only by the owner of the specified phoneHash.
    modifier authorised(bytes32 phoneNumber) {
        bytes32 phoneHash = _hash(phoneNumber);
        address owner = records[phoneHash].owner;
        require(owner == msg.sender, "caller is not authorised");
        _;
    }

    /**
     * @dev Sets the record for a phoneHash.
     * @param phoneNumber The phoneNumber to update.
     * @param owner The address of the new owner.
     * @param resolver The address the phone number resolves to.
     * @param label The label is specified label of the resolver.
     */
    function setPhoneRecord(
        bytes32 phoneNumber,
        address owner,
        address resolver,
        string memory label
    ) external virtual {
        // hash phone number before storing it on chain
        bytes32 phoneHash = _hash(phoneNumber);
        ResolverRecord storage resolverRecordData = resolverRecordMapping[
            label
        ];

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;
        }
        records[phoneHash].phoneHash = phoneHash;
        records[phoneHash].owner = owner;
        records[phoneHash].createdAt = block.timestamp;
        records[phoneHash].exists = true;
        records[phoneHash].wallet.push(resolverRecordData);
        emit PhoneRecordCreated(phoneHash, resolver, owner);
    }

    /**
     * @dev Returns the address that owns the specified phone number phoneHash.
     * @param phoneNumber The specified phoneHash.
     */
    function getRecord(bytes32 phoneNumber)
        external
        view
        returns (
            address owner,
            ResolverRecord[] memory,
            bytes32,
            uint256 createdAt,
            bool exists
        )
    {
        return _getRecord(phoneNumber);
    }

    /**
     * @dev Returns the address that owns the specified phone number.
     * @param phoneNumber The specified phoneNumber.
     * @return address of the owner.
     */
    function getOwner(bytes32 phoneNumber)
        public
        view
        virtual
        returns (address)
    {
        bytes32 phoneHash = _hash(phoneNumber);
        address addr = records[phoneHash].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified phoneHash and label.
     * @param phoneNumber The specified phoneHash.
     * @return address of the resolver.
     */
    function getResolver(bytes32 phoneNumber)
        public
        view
        virtual
        returns (ResolverRecord[] memory)
    {
        bytes32 phoneHash = _hash(phoneNumber);
        return records[phoneHash].wallet;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param phoneNumber The specified phoneHash.
     * @return Bool if record exists
     */
    function recordExists(bytes32 phoneNumber) public view returns (bool) {
        bytes32 phoneHash = _hash(phoneNumber);
        return records[phoneHash].exists;
    }

    /**
     * @dev Transfers ownership of a phoneHash to a new address. May only be called by the current owner of the phoneHash.
     * @param phoneNumber The phoneHash to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 phoneNumber, address owner)
        public
        virtual
        authorised(phoneNumber)
    {
        bytes32 phoneHash = _setOwner(phoneNumber, owner);
        emit Transfer(phoneHash, owner);
    }

    /**
     * @dev Sets the resolver address for the specified phoneHash.
     * @param phoneNumber The phoneNumber to update.
     * @param resolver The address of the resolver.
     * @param label The specified label of the resolver.
     */
    function linkPhoneToWallet(
        bytes32 phoneNumber,
        address resolver,
        string memory label
    ) public virtual authorised(phoneNumber) {
        bytes32 phoneHash = _hash(phoneNumber);
        _linkPhoneNumberToWallet(phoneHash, resolver, label);
        emit PhoneLinked(phoneHash, resolver);
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param phoneNumber The specified phoneHash.
     * @param label The specified label of the resolver.
     * @return Bool if record exists
     */
    function resolverExists(bytes32 phoneNumber, string memory label)
        public
        view
        returns (bool)
    {
        bytes32 phoneHash = _hash(phoneNumber);
        ResolverRecord memory resolverRecordData = resolverRecordMapping[label];
        return resolverRecordData.exists;
    }

    /**
     * @dev Returns an existing label for the specified phone number phoneHash.
     * @param phoneNumber The specified phoneHash.
     * @param label The specified label of the resolver.
     */
    function getResolverDetails(bytes32 phoneNumber, string memory label)
        external
        view
        returns (ResolverRecord memory resolver)
    {
        return _getResolverDetails(phoneNumber, label);
    }

    function _setOwner(bytes32 phoneNumber, address owner)
        internal
        virtual
        returns (bytes32)
    {
        bytes32 phoneHash = _hash(phoneNumber);
        records[phoneHash].owner = owner;
        return phoneHash;
    }

    function _linkPhoneNumberToWallet(
        bytes32 phoneNumber,
        address resolver,
        string memory label
    ) internal {
        bytes32 phoneHash = _hash(phoneNumber);
        ResolverRecord storage resolverRecordData = resolverRecordMapping[
            label
        ];

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;
        }

        records[phoneHash].wallet.push(resolverRecordData);
    }

    /**
     * @dev Returns the hash for a given phoneNumber
     * @param phoneNumber The phoneNumber to hash
     * @return The ENS node hash.
     */
    function _hash(bytes32 phoneNumber) internal pure returns (bytes32) {
        return keccak256(abi.encode(phoneNumber));
    }

    /**
     * @dev Returns the address that owns the specified phone number phoneHash.
     * @param phoneNumber The specified phoneHash.
     */
    function _getRecord(bytes32 phoneNumber)
        internal
        view
        returns (
            address owner,
            ResolverRecord[] memory,
            bytes32,
            uint256 createdAt,
            bool exists
        )
    {
        bytes32 phoneHash = _hash(phoneNumber);
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.exists, "phone record not found");

        return (
            recordData.owner,
            recordData.wallet,
            recordData.phoneHash,
            recordData.createdAt,
            recordData.exists
        );
    }

    /**
     * @dev Returns an existing label for the specified phone number phoneHash.
     * @param phoneNumber The specified phoneHash.
     * @param label The specified label.
     */
    function _getResolverDetails(bytes32 phoneNumber, string memory label)
        internal
        view
        returns (ResolverRecord memory resolver)
    {
        bytes32 phoneHash = _hash(phoneNumber);
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.exists, "phone record not found");
        ResolverRecord storage resolverRecordData = resolverRecordMapping[
            label
        ];
        return (resolverRecordData);
    }
}
