// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);
}

contract PriceConverter {
	/// Oracle feed pricing
	AggregatorInterface public priceFeedContract;

	constructor(address _priceAggregator) {
		priceFeedContract = AggregatorInterface(_priceAggregator);
	}
}
