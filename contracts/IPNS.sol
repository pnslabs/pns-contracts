pragma solidity 0.8.9;

interface IPNS {
    function setPhoneRecord(
        uint256 phoneHash,
        address owner,
        address wallet,
        string memory label
    ) external;

    function resolverExists(bytes32 phoneNumber, string memory label)
        external
        view
        returns (bool);

    function linkPhoneToWallet(
        bytes32 phoneNumber,
        address wallet,
        string memory label
    ) external;

    function setOwner(bytes32 phoneNumber, address owner) external;

    function recordExists(bytes32 phoneNumber) external view returns (bool);

    function getResolver(bytes32 phoneNumber, string memory label)
        external
        view
        returns (address);

    function getOwner(bytes32 phoneNumber) external view returns (address);

    function getRecord(bytes32 phoneHash)
        external
        view
        returns (
            address owner,
            bytes32,
            uint64 createdAt,
            bool exists
        );

    function getResolverDetails(bytes32 phoneHash, string memory label)
        external
        view
        returns (
            address wallet,
            uint256 createdAt,
            bool exists
        );
}
