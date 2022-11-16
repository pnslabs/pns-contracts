import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../../utils/util');
const { deployContract } = require('../../scripts/deploy-helpers');

describe('PNS Record Owner', () => {
  let pnsContract;
  const phoneNumber = keccak256('07084462591');
  const label = 'ETH';
  const address = '0xcD058D84F922450591AD59303AA2B4A864da19e6';

  before(async function () {
    const { pnsContract: _pnsContract } = await deployContract();
    pnsContract = _pnsContract;
  });

  it('should create a new record and emit an event', async function () {
    await expect(pnsContract.setPhoneRecord(phoneNumber, address, address, label)).to.emit(
      pnsContract,
      'PhoneRecordCreated',
    );
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
