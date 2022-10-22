const { run: _run } = require('hardhat');

const verify = async (contractAddress, args) => {
  console.log('Verifying Etherscan contract...');
  try {
    await _run('verify:verify', {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes('already verified')) {
      console.log('Contract already verified!');
    } else {
      console.log(e);
    }
  }
};

module.exports = { verify };
