const { assert } = require('chai');
const { deployContract, deployUpgradedContract } = require('../../scripts/deploy');

describe('PNS Contract Upgrade', () => {
  let pnsRegistryContract;

  before(async function () {
    const { pnsRegistryContract: _pnsRegistryContract } = await deployContract();
    pnsRegistryContract = _pnsRegistryContract;
  });

  it('gets the correct version of the V1 contract', async () => {
    const version = await pnsRegistryContract.getVersion();

    assert.equal(version, 1);
  });

  it('upgrades the contract and gets the correct version', async () => {
    const { upgradedPNSContract } = await deployUpgradedContract(pnsRegistryContract);
    const version = await upgradedPNSContract.getVersion();

    assert.equal(version, 2);
  });
});
