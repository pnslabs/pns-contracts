const { keccak256: _keccak256 } = require('./utils/util');

let testVariables = {
  signer1: null,
  signer2: null,
  adminAddress: null,
  zeroAddress: '0x0000000000000000000000000000000000000000',
  address1: '0xcD058D84F922450591AD59303AA2B4A864da19e6',
  address2: '0x368d517d45F984990Fc7c38e2Eaa503f5b5c7Ce6',
  address3: '0xe1563051F86414C5Fc3b7fa8cde3eBf50293d577',
  phoneNumber1: _keccak256('07084462591'),
  phoneNumber2: _keccak256('08084442592'),
  phoneNumber3: _keccak256('09088442572'),
  label1: 'ETH',
  label2: 'BTC',
  resolverCreatedLength: 0,
  pnsContract: null,
  twoYearsInSeconds: 63072000,
  thirtyDaysInSeconds: 2592000,
};

module.exports = {
  testVariables,
};
