pragma solidity 0.7.0;

interface IPNS {
    // logs when you sets the record for a phoneHash.
    event PhoneRecordCreated(bytes32 phoneHash, address wallet, address owner);

    // logs when transfers ownership of a phoneHash to a new address
    event Transfer(bytes32 phoneHash, address owner);

    //logs when a resolve address is set for the specified phoneHash.
    event PhoneLinked(bytes32 phoneHash, address wallet);

    function setPhoneRecord(
        uint256 phoneHash,
        address owner,
        address wallet
    ) external;

    function getRecord(bytes32 phoneHash)
        external
        view
        returns (
            address owner,
            address wallet,
            bytes32,
            uint64 createdAt,
            bool exists
        );
}
