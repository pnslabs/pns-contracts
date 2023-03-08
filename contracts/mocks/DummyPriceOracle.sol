// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);
}

contract DummyPriceOracle is AggregatorInterface {
	int256 value;

	constructor(int256 _value) {
		set(_value);
	}

	function set(int256 _value) public {
		value = _value;
	}

	function latestAnswer() external view returns (int256) {
		return value;
	}
}
