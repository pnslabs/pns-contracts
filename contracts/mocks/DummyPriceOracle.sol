// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract DummyPriceOracle {
	int256 value;

	constructor(int256 _value) public {
		set(_value);
	}

	function set(int256 _value) public {
		value = _value;
	}

	function latestRoundData() public view returns (int256) {
		return value;
	}
}
