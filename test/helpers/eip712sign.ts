const ethUtil = require('ethereumjs-util');
const { getMessage } = require('eip-712');

const typedData = {
  types: {
    EIP712Domain: [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ],
    Whitelist: [{ name: 'user', type: 'address' }],
  },
  domain: {
    name: 'PNS - core',
    version: 'v1.0.0',
    chainId: 31337,
    verifyingContract: '',
  },
  primaryType: 'Whitelist',
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
