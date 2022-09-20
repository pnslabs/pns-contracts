pragma solidity 0.8.9;
import "./IPNSSchema.sol";

contract PNS is IPNSSchema {
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

    mapping(string => ResolverRecord) resolverRecordMapping;
    mapping(bytes32 => PhoneRecord) records;

    // Permits modifications only by the owner of the specified phoneHash.
    modifier authorised(bytes32 phoneHash) {
        address owner = records[phoneHash].owner;
        require(owner == msg.sender, "caller is not authorised");
        _;
    }

    /**
     * @dev Sets the record for a phoneHash.
     * @param phoneHash The phoneHash to update.
     * @param owner The address of the new owner.
     * @param resolver The address the phone number resolves to.
     * @param label The label is specified label of the resolver.
     */
    function setPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) external virtual {
        // hash phone number before storing it on chain

        recordExists(phoneHash);
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
            bool exists
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
    ) public virtual authorised(phoneHash) {
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

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;
        }

        records[phoneHash].wallet.push(resolverRecordData);
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
            bool exists
        )
    {
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
}
