//TODO Split contract functionalities into different sub contracts 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract PriceOracle {

    //testnet priceFeed goreil
    AggregatorV3Interface private constant ETH_USD_CHAINLINK = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

   /**
     * @dev Returns the ETH price in USD ( DAI) using chainlink
     */
    function getEtherPriceInUSD() internal view returns (uint256) {
        (uint80 roundID,
         int256 price,
          ,
          ,
         uint80 answeredInRound) = ETH_USD_CHAINLINK.latestRoundData();
        require(answeredInRound >= roundID, "getEtherPrice: Chainlink Price Stale");
        // Chainlink returns 8 decimal places so we convert
        return uint256(price) * (10**8);
    }
}