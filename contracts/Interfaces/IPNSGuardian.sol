// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IPNSSchema.sol';

/**
 * @title Interface for the PNS Guardian contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Guardian.
 * @dev All function call interfaces are defined here.
 */
interface IPNSGuardian is IPNSSchema {
    function setVerificationStatus(bytes32 phoneHash, bool status, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s)
    external;

    function setGuardianVerifier(address _guardianVerifier) external;

    function getVerificationStatus(bytes32 phoneHash) external view returns (bool);
    function getVerificationRecord(bytes32 phoneHash) external view returns (VerificationRecord memory);


}
