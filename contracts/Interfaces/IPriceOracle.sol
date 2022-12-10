// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Interface for the PNS Price Oracle contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Price Oracle contract.
 * @dev All function call interfaces are defined here.
 */
interface IPriceOracle {
    function getEtherPriceInUSD() external view returns (uint256);

}
