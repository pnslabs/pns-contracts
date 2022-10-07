const { keccak256: _keccak256 } = require('./utils/util');

const networkConfig = {
  31337: {
    name: 'localhost',
  },
  42: {
    name: 'kovan',
  },
  4: {
    name: 'rinkeby',
  },
};

const developmentChains = ['hardhat', 'localhost'];

let testVariables = {
  normalAccount: '0xcD058D84F922450591AD59303AA2B4A864da19e6',
  phoneNumber: _keccak256('07084462591'),
  label1: 'ETH',
  label2: 'BTC',
  resolverCreatedLength: 0,
  pnsContract: null,
  adminAddress: null,
};

module.exports = {
  networkConfig,
  developmentChains,
  testVariables,
};
