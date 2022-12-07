// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Interfaces/IPNSSchema.sol";




/// @title Handles the authentication of the PNS registry
/// @author  PNS core team
/// @notice The PNS Guardian is responsible for authenticating the records created in PNS registry
contract PNSGuardian is IPNSSchema {
    /// the guardian layer address that updates verification state
    address public guardianVerifier;

    mapping(bytes32 => VerificationRecord) public verificationRecords;

    event PhoneVerified(address indexed owner, bytes32 indexed phoneHash, uint256 verifiedAt);

    constructor() {
        guardianVerifier = msg.sender;
    }

    /**
  * @dev Permits modifications only by an guardian Layer Address.
     */
    modifier onlyGuardianVerifier() {
        require(msg.sender == guardianVerifier, "onlyGuardianVerifier: ");
        _;
    }

    /**
 * @notice updates guardian layer address
     */
    function setGuardianVerifier(address _guardianVerifier)
    public
    onlyGuardianVerifier
    {
        guardianVerifier = _guardianVerifier;
    }

    /**
 * @notice updates user authentication state once authenticated
     */
    function setVerificationStatus(bytes32 phoneHash, bool status, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s)
    public
    onlyGuardianVerifier
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);

        verificationRecords[phoneHash] = VerificationRecord({
        owner : signer,
        phoneHash : phoneHash,
        verifiedAt : block.timestamp,
        exists : true,
        isVerified : status
        });
    }

    /**
    * @notice gets user verification state
        */
    function getVerificationStatus(bytes32 phoneHash) external view returns (bool) {
        return verificationRecords[phoneHash].isVerified;
    }

    /**
    * @notice gets user verification records
        */
    function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory) {
        return verificationRecords[phoneHash];
    }



}
