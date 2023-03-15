// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

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

contract DummyPriceOracle is AggregatorV3Interface {
	int256 value;
	uint8 _decimals = 8;
	string _description = '';
	uint256 _version = 3;

	constructor(int256 _value) {
		set(_value);
	}

	function set(int256 _value) public {
		value = _value;
	}

	function setDecimals(uint8 __decimals) external {
		_decimals = __decimals;
	}

	function decimals() external view returns (uint8) {
		return _decimals;
	}

	function description() external view returns (string memory) {
		return _description;
	}

	function version() external view returns (uint256) {
		return _version;
	}

	function getRoundData(
		uint80 /** _roundId */
	)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		return (1, value, block.timestamp, block.timestamp, 1);
	}

	function latestRoundData()
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		return (1, value, block.timestamp, block.timestamp, 1);
	}
}
