require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-truffle5");
require("dotenv").config();
const { utils } = require("ethers");
const PRIVATE_KEY_GANACHE = process.env.PRIVATE_KEY_GANACHE;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
      },
    ],
    optimizer: {
      enabled: true,
      runs: 1,
    },
  },
  networks: {
    localhost: {
      url: `http://localhost:8545`,
      accounts: [`0x${PRIVATE_KEY_GANACHE}`],
      gasPrice: parseInt(utils.parseUnits("132", "gwei")),
      allowUnlimitedContractSize: true,
    },
  },
};
