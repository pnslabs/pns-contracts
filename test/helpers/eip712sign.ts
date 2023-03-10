//hardhat depoyment path default guardian
const VERIFYING_CONTRACT = '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';
// testing chainID
const chainID = 1337;

export const domain = {
  name: 'PNS Guardian',
  version: '1.0',
  //hardhat chain ID
  chainId: chainID,
  verifyingContract: VERIFYING_CONTRACT,
};

export const PNSTypes = {
  verify: [{ name: 'phoneHash', type: 'bytes32' }],
};

// const typedData = {
//   types: {
//     EIP712Domain: [
//       { name: 'name', type: 'string' },
//       { name: 'version', type: 'string' },
//       { name: 'chainId', type: 'uint256' },
//       { name: 'verifyingContract', type: 'address' },
//     ],
//     verify: [{ name: 'phoneHash', type: 'bytes32' }],
//   },
//   domain: domain,
//   primaryType: types,
//   message: {
//     user: '',
//   },
// };
