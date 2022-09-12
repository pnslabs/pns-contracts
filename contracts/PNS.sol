pragma solidity >=0.7.0;
import "./IPNS.sol";

contract PNS is IPNS {
    // assign phone number phoneHash to an address
    // transfer ownership of address to a new phone number
    // unlink phone number phoneHash to an address
    // get phone number tied to an address
    // get address tied to a phone number

    struct PhoneRecord {
        address owner;
        address wallet;
        bytes32 phoneHash;
        uint64 createdAt;
        bool exists;
    }

    mapping(bytes32 => PhoneRecord) records;

    // Permits modifications only by the owner of the specified phoneHash.
    modifier authorised(bytes32 phoneHash) {
        address owner = records[phoneHash].owner;
        require(owner == msg.sender);
        _;
    }

    /**
     * @dev Sets the record for a phoneHash.
     * @param phoneNumber The phoneNumber to update.
     * @param owner The address of the new owner.
     * @param wallet The address the phone number resolves to.
     */
    function setPhoneRecord(
        uint256 phoneHash,
        address owner,
        address wallet
    ) external virtual override {
        setOwner(phoneHash, owner);
        if (wallet != records[phoneHash].wallet) {
            records[phoneHash].wallet = wallet;
        }
        records[phoneHash].createdAt = block.timestamp;
        records[phoneHash].exists = true;
        emit PhoneRecordCreated(phoneHash, wallet, owner);
    }

    /**
     * @dev Returns the address that owns the specified phone number phoneHash.
     * @param phoneHash The specified phoneHash.
     */
    function getRecord(bytes32 phoneHash)
        public
        view
        virtual
        override
        returns (
            address owner,
            address wallet,
            bytes32 phoneHash,
            uint64 createdAt,
            bool exists
        )
    {
        PhoneRecords memory recordData = records[phoneHash];
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
     * @dev Returns the address that owns the specified phone number phoneHash.
     * @param phoneHash The specified phoneHash.
     * @return address of the owner.
     */
    function getOwner(bytes32 phoneHash)
        public
        view
        virtual
        override
        returns (address)
    {
        address addr = records[phoneHash].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified phoneHash.
     * @param phoneHash The specified phoneHash.
     * @return address of the resolver.
     */
    function getResolver(bytes32 phoneHash)
        public
        view
        virtual
        override
        returns (address)
    {
        return records[phoneHash].wallet;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param phoneHash The specified phoneHash.
     * @return Bool if record exists
     */
    function recordExists(bytes32 phoneHash)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        override
        authorised(phoneHash)
    {
        _setOwner(phoneHash, owner);
        emit Transfer(phoneHash, owner);
    }

    /**
     * @dev Sets the resolver address for the specified phoneHash.
     * @param phoneHash The phoneHash to update.
     * @param resolver The address of the resolver.
     */
    function linkPhoneToWallet(bytes32 phoneHash, address wallet)
        public
        virtual
        override
        authorised(phoneHash)
    {
        _linkPhoneNumberToWallet(phoneHash, wallet);
        emit PhoneLinked(phoneHash, wallet);
    }

    function _setOwner(bytes32 phoneHash, address owner) internal virtual {
        records[phoneHash].owner = owner;
    }

    function _linkPhoneNumberToWallet(bytes32 phoneHash, address wallet)
        internal
    {
        if (wallet != records[phoneHash].wallet) {
            records[phoneHash].wallet = wallet;
        }
    }
}
