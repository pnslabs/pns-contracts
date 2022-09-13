pragma solidity 0.8.9;

interface IPNS {
    function setPhoneRecord(
        uint256 phoneHash,
        address owner,
        address wallet,
        string memory network
    ) external;

    function getRecord(bytes32 phoneHash)
        external
        view
        returns (
            address owner,
            bytes32,
            uint64 createdAt,
            bool exists
        );

    function getNetwork(bytes32 phoneHash, string memory network)
        external
        view
        returns (
            address wallet,
            uint256 createdAt,
            bool exists
        );
}
