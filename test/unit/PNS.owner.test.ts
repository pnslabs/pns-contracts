import { ethers } from 'hardhat';

const { assert } = require('chai');
const { keccak256: _keccak256 } = require('../../utils/util');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Record Owner', () => {
  let pnsContract;
  const phoneNumber = _keccak256('07084462591');
  const address = '0x368d517d45F984990Fc7c38e2Eaa503f5b5c7Ce6';

  before(() => {
    pnsContract = testVariables.pnsContract;
  });

  it('gets the correct owner of the record', async () => {
    const recordOwner = await pnsContract.getOwner(phoneNumber);

    assert.equal(recordOwner, address);
  });

  // it('changes record owner and emits an event', async () => {
  //   await expect(
  //     pnsContract.connect(address3).setOwner(phoneNumber1, adminAddress),
  //   ).to.emit(pnsContract, 'Transfer');
  // });

  // it('gets newly transfered record owner', async () => {
  //   const recordOwner = await pnsContract.getOwner(phoneNumber1);
  //   assert.equal(recordOwner, address1);
  // });
});
