// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract PriceOracle is Initializable {

    AggregatorV3Interface internal _aggregatorV3Interface;

    function initialize(address _aggregatorV3Address) external initializer {
        _aggregatorV3Interface = AggregatorV3Interface(_aggregatorV3Address);
    }

    /**
      * @dev Returns the ETH price in USD ( DAI) using chainlink
     */
    function getEtherPriceInUSD() public view returns (uint256) {
        (uint80 roundID,
        int256 price,
        ,
        ,
        uint80 answeredInRound) = _aggregatorV3Interface.latestRoundData();
        require(answeredInRound >= roundID, "getEtherPrice: Chainlink Price Stale");
        // Chainlink returns 8 decimal places so we convert
        return uint256(price) * (10 ** 8);
    }
}
