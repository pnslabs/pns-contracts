// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Interface for the PNS Resolver contract.
 * @author PNS foundation core
 * @notice This only serves as a function guide for the PNS Resolver contract.
 * @dev All function call interfaces are defined here.
 */

interface IPriceConverter {
	function getEtherPriceInUSD() external view returns (uint256);

	function convertETHToUSD(uint256 ethAmount) external view returns (uint256);

	function convertUSDToETH(uint256 usdAmount) external view returns (uint256);
}
