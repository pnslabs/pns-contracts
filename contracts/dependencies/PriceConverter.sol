// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);
}

contract PriceConverter is Ownable {
	/// Oracle feed pricing
	AggregatorInterface public priceFeedContract;

	constructor(address _priceAggregator) {
		priceFeedContract = AggregatorInterface(_priceAggregator);
	}

	/**
	 * @dev converts ETH to USD in wei
	 */
	function convertETHToUSD(uint256 ethAmount) public view returns (uint256) {
		uint256 ethPrice = getEtherPriceInUSD();
		uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1e18;
		return uint256(ethAmountInUSD);
	}

	/**
	 * @dev converts USD to ETHER in Wei
	 */
	function convertUSDToETH(uint256 usdAmount) public view returns (uint256) {
		uint256 ethPrice = getEtherPriceInUSD();
		uint256 ethAmountInUSD = (usdAmount * 1e18) / ethPrice;
		return uint256(ethAmountInUSD);
	}

	/**
	 * @dev Returns the latest price
	 */
	function getEtherPriceInUSD() public view returns (uint256) {
		int256 answer = priceFeedContract.latestAnswer();
		// Chainlink returns 8 decimal places so we convert to wei
		return uint256(answer * 1e10);
	}

	/**
	 * @dev changes the price aggregator
	 */
	function changeAggregator(AggregatorInterface _priceFeedContract) external onlyOwner {
		priceFeedContract = _priceFeedContract;
	}
}
