// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	function getRoundData(uint80 _roundId)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestRoundData()
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);
}

contract PriceConverter is Ownable {
	/// Oracle feed pricing
	AggregatorV3Interface public priceFeedContract;

	constructor(address _priceAggregator) {
		priceFeedContract = AggregatorV3Interface(_priceAggregator);
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
		(uint80 roundID, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = priceFeedContract.latestRoundData();

		// check that answer is indeed from the last known round
		require(answeredInRound == roundID, 'Stale price');
		// check that answer is within an allowed margin of freshness by checking updated at was updated less than an hour ago
		require(updatedAt > block.timestamp - 3600, 'Answer is not from last known round');
		// check returned answer is not zero
		require(answer > 0, 'Negative price');

		// safe to cast answer into uint256 as we require it to be greater than 0 or above and decimals returns a uint8
		// this also assumes that aggregator decimals won't surpass 18 as it will revert with a panic error also solidity doesn't support negative exponents yet
		return uint256(answer) * (10**(18 - priceFeedContract.decimals()));
	}

	/**
	 * @dev changes the price aggregator
	 */
	function changeAggregator(AggregatorV3Interface _priceFeedContract) external onlyOwner {
		priceFeedContract = _priceFeedContract;
	}
}
