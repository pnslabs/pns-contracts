const ethUtil = require('ethereumjs-util');
const { getMessage } = require('eip-712');

//hardhat depoyment path
const VERIFYING_CONTRACT = '';
// testing chainID
const chainID = 1;
const typedData = {
  types: {
    EIP712Domain: [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ],
    verify: [{ name: 'phoneHash', type: 'bytes32' }],
  },
  domain: {
    name: 'PNS Guardian',
    version: '1.0',
    chainId: 1,
    verifyingContract: VERIFYING_CONTRACT,
  },
  primaryType: 'verifyPhoneHash',
  message: {
    user: '',
  },
};

function replaceAddresses(contractAddress: string, from: string) {
  typedData.domain.verifyingContract = contractAddress;
  typedData.message.user = from;
}

const signEIP712Message = (contractAddress: any, from: any, privateKey: any) => {
  replaceAddresses(contractAddress, from);

  // Sign
  const message = getMessage(typedData, true);
  const { r, s, v } = ethUtil.ecsign(message, privateKey);
  const sigHex = `0x${r.toString('hex')}${s.toString('hex')}${('0' + v.toString(16)).slice(-2)}`;

  return sigHex;
};

export default signEIP712Message;
