import '@nomicfoundation/hardhat-toolbox';
import 'dotenv/config';
import 'hardhat-contract-sizer';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@openzeppelin/hardhat-upgrades';
import { utils } from 'ethers';
// import { HardhatUserConfig, task } from 'hardhat/config';

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.9',
      },
    ],
    optimizer: {
      enabled: true,
      runs: 1,
    },
  },
  networks: {
    hardhat: {
      mining: {
        auto: true,
      },
      // forking: {
      //   url: 'https://mainnet.infura.io/v3/93c3c3bccee54144aa42c29ad05ef4f5',
      //   blockNumber: 14622817,
      // },
    },
    localhost: {
      url: `http://127.0.0.1:8545`,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      gasPrice: parseInt(utils.parseUnits('132', 'gwei')),
    },
  },
};
