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

    struct PhoneRecord {
        address owner;
        address wallet;
        bytes32 phoneHash;
        uint256 createdAt;
        bool exists;
    }

    mapping(bytes32 => PhoneRecord) records;

    // Permits modifications only by the owner of the specified phoneHash.
    modifier authorised(bytes32 phoneNumber) {
        bytes32 phoneHash = _hash(phoneNumber);
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
        bytes32 phoneNumber,
        address owner,
        address wallet
    ) external virtual {
        // hash phone number before storing it on chain
        bytes32 phoneHash = _hash(phoneNumber);
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
     * @param phoneNumber The specified phoneHash.
     */
    function getRecord(bytes32 phoneNumber)
        external
        view
        returns (
            address owner,
            address wallet,
            bytes32,
            uint256 createdAt,
            bool exists
        )
    {
        return _getRecord(phoneNumber);
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
            address wallet,
            bytes32,
            uint256 createdAt,
            bool exists
        )
    {
        bytes32 phoneHash = _hash(phoneNumber);
        PhoneRecord memory recordData = records[phoneHash];
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
     * @dev Returns the address of the resolver for the specified phoneHash.
     * @param phoneNumber The specified phoneHash.
     * @return address of the resolver.
     */
    function getResolver(bytes32 phoneNumber)
        public
        view
        virtual
        returns (address)
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
     * @param wallet The address of the resolver.
     */
    function linkPhoneToWallet(bytes32 phoneNumber, address wallet)
        public
        virtual
        authorised(phoneNumber)
    {
        bytes32 phoneHash = _hash(phoneNumber);
        _linkPhoneNumberToWallet(phoneHash, wallet);
        emit PhoneLinked(phoneHash, wallet);
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

    function _linkPhoneNumberToWallet(bytes32 phoneNumber, address wallet)
        internal
    {
        bytes32 phoneHash = _hash(phoneNumber);
        if (wallet != records[phoneHash].wallet) {
            records[phoneHash].wallet = wallet;
        }
    }

    /**
     * @dev Returns the hash for a given phoneNumber
     * @param phoneNumber The phoneNumber to hash
     * @return The ENS node hash.
     */
    function _hash(bytes32 phoneNumber) internal pure returns (bytes32) {
        return keccak256(abi.encode(phoneNumber));
    }
}
