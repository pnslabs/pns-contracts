import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256: _keccak256 } = require('../../utils/util');

describe('PNS Record', () => {
  let adminAccount;
  let pnsContract;
  let adminAddress;
  const phoneNumber1 = _keccak256('07084462591');
  const phoneNumber2 = _keccak256('08084442592');
  const label = 'ETH';

  before(async function () {
    [adminAccount] = await ethers.getSigners();
    adminAddress = adminAccount.address;

    const PNSContract = await ethers.getContractFactory('PNS');

    pnsContract = await PNSContract.deploy();
  });

  it('should create a new record and emit an event', async function () {
    await expect(pnsContract.setPhoneRecord(phoneNumber1, adminAddress, adminAddress, label)).to.emit(
      pnsContract,
      'PhoneRecordCreated',
    );
  });

  it('should throw error when creating a record with an existing phone', async function () {
    await expect(pnsContract.setPhoneRecord(phoneNumber1, adminAddress, adminAddress, label)).to.be.revertedWith(
      'phone record already exists',
    );
  });

  it('verifies that new recorded created exist', async () => {
    const phoneRecordExist = await pnsContract.recordExists(phoneNumber1);

    assert.equal(phoneRecordExist, true);
  });

  it('should return false if record does not exist', async () => {
    const phoneRecordExist = await pnsContract.recordExists(phoneNumber2);

    assert.equal(phoneRecordExist, false);
  });

  it('ties the correct owner to record', async () => {
    const phoneRecord = await pnsContract.getRecord(phoneNumber1);
    assert.equal(phoneRecord.owner, adminAddress);
  });
});
