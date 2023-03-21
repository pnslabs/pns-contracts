const { assert } = require('chai');
const { deployContract, deployRegistryUpgradedContract } = require('../scripts/deploy');

describe('PNS Contract Upgrade', () => {
  let pnsRegistryContract;

  before(async function () {
    const { pnsRegistryContract: _pnsRegistryContract } = await deployContract();
    pnsRegistryContract = _pnsRegistryContract;
  });

  it('should upgrade the registry contract', async () => {
    // gets the correct version of the registry contract
    assert.equal(await pnsRegistryContract.getVersion(), 1);

    // upgrade the registry contract and gets the correct version
    const { upgradedPNSRegistryContract } = await deployRegistryUpgradedContract(pnsRegistryContract.address);
    assert.equal(await upgradedPNSRegistryContract.getVersion(), 2);
  });
});
