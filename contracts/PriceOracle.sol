//TODO Split contract functionalities into different sub contracts 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceOracle {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
	    /// Chainlink Oracle (Ether)
        priceFeed = AggregatorV3Interface(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
    }

   /**
     * @dev Returns the ETH price in DAI using chainlink
     */
    function getEtherPrice() public view returns (uint256) {
        (uint80 roundID, int256 price, , , uint80 answeredInRound) = priceFeed.latestRoundData();
        require(answeredInRound >= roundID, "getEtherPrice: Chainlink Price Stale");
        require(price != 0, "getEtherPrice: Chainlink Malfunction");
        // Chainlink returns 8 decimal places so we convert
        return uint256(price) * (10**10);
    }
}