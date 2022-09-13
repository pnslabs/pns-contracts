pragma solidity 0.8.9;

interface IPNS {
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
