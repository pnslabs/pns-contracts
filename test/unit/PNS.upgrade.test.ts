const { assert } = require('chai');
const { deployContract, deployUpgradedContract } = require('../../scripts/deploy-helpers');

describe('PNS Contract Upgrade', () => {
  let pnsContract;

  before(async function () {
    const { pnsContract: _pnsContract } = await deployContract();
    pnsContract = _pnsContract;
  });

  it('gets the correct version of the V1 contract', async () => {
    const version = await pnsContract.getVersion();

    assert.equal(version, 1);
  });

  it('upgrades the contract and gets the correct version', async () => {
    const { upgradedPNSContract } = await deployUpgradedContract(pnsContract);
    const version = await upgradedPNSContract.getVersion();

    assert.equal(version, 2);
  });
});
