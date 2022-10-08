import { network } from 'hardhat';

const { assert, expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Record Owner', () => {
  const { phoneNumber1, address1 } = testVariables;

  it('gets the correct owner of the record', async () => {
    const recordOwner = await testVariables.pnsContract.getOwner(phoneNumber1);

    assert.equal(recordOwner, testVariables.adminAddress);
  });

  it('changes record owner and emits an event', async () => {
    await expect(
      testVariables.pnsContract.setOwner(phoneNumber1, address1, { from: testVariables.adminAddress }),
    ).to.emit(testVariables.pnsContract, 'Transfer');
  });

  it('gets newly transfered record owner', async () => {
    const recordOwner = await testVariables.pnsContract.getOwner(phoneNumber1);
    assert.equal(recordOwner, address1);
  });
});
