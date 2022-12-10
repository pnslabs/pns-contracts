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
      runs: 200,
    },
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
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
      //truffle
      url: `http://127.0.0.1:8545`,
      accounts: process.env.PRIVATE_KEY_GANACHE !== undefined ? [process.env.PRIVATE_KEY_GANACHE] : [],
      allowUnlimitedContractSize: true,
      gasPrice: parseInt(`${utils.parseUnits('132', 'gwei')}`),
      blockGasLimit: 12000000,
    },
    ethereum_mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: parseInt(`${utils.parseUnits('132', 'gwei')}`),
    },
    ethereum_goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: parseInt(`${utils.parseUnits('132', 'gwei')}`),
      blockGasLimit: 12000000,
    },
    bnb_mainnet: {
      url: `https://bsc-dataseed.binance.org/`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: parseInt(`${utils.parseUnits('132', 'gwei')}`),
    },
    bnb_testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: parseInt(`${utils.parseUnits('132', 'gwei')}`),
      allowUnlimitedContractSize: true,
      blockGasLimit: 12000000,
    },
    polygon_mainnet: {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: parseInt(`${utils.parseUnits('132', 'gwei')}`),
    },
    polygon_testnet: {
      url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: parseInt(`${utils.parseUnits('132', 'gwei')}`),
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
