import { network } from 'hardhat';

const { assert, expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Record Owner', () => {
  const { phoneNumber1, address3 } = testVariables;

  it('gets the correct owner of the record', async () => {
    const recordOwner = await testVariables.pnsContract.getOwner(phoneNumber1);

    assert.equal(recordOwner, address3);
  });

  // it('changes record owner and emits an event', async () => {
  //   await expect(
  //     testVariables.pnsContract.connect(address3).setOwner(phoneNumber1, testVariables.adminAddress),
  //   ).to.emit(testVariables.pnsContract, 'Transfer');
  // });

  // it('gets newly transfered record owner', async () => {
  //   const recordOwner = await testVariables.pnsContract.getOwner(phoneNumber1);
  //   assert.equal(recordOwner, address1);
  // });
});
