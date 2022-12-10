//TODO Split contract functionalities into different sub contracts

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract PriceOracle {

    AggregatorV3Interface internal _aggregatorV3Interface;

    constructor(address _aggregatorV3Address) {
        _aggregatorV3Interface = AggregatorV3Interface(_aggregatorV3Address);
    }

    AggregatorV3Interface ETH_USD_CHAINLINK = AggregatorV3Interface(_aggregatorV3Interface);

    /**
      * @dev Returns the ETH price in USD ( DAI) using chainlink
     */
    function getEtherPriceInUSD() public view returns (uint256) {
        (uint80 roundID,
        int256 price,
        ,
        ,
        uint80 answeredInRound) = ETH_USD_CHAINLINK.latestRoundData();
        require(answeredInRound >= roundID, "getEtherPrice: Chainlink Price Stale");
        // Chainlink returns 8 decimal places so we convert
        return uint256(price) * (10 ** 8);
    }
}
