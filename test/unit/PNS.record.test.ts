import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../../utils/util');
const { deployContract } = require('../../helper-hardhat-config');

describe('PNS Record', () => {
  let pnsContract;
  let adminAddress;
  const phoneNumber1 = keccak256('07084462591');
  const phoneNumber2 = keccak256('08084442592');
  const label = 'ETH';
  const authFee1 = ethers.utils.parseEther('1');
  const authFee2 = ethers.utils.parseEther('0.9');

  before(async function () {
    const { pnsContract: _pnsContract, adminAddress: _adminAddress } = await deployContract();
    pnsContract = _pnsContract;
    adminAddress = _adminAddress;
  });

  it('should throw error when creating a record with less fee', async function () {
    await expect(
      pnsContract.setPhoneRecord(phoneNumber1, adminAddress, adminAddress, label, { value: authFee2 }),
    ).to.be.revertedWith('fee must be greater than or equal to the auth fee');
  });

  it('creates a new record', async function () {
    await expect(
      pnsContract.setPhoneRecord(phoneNumber1, adminAddress, adminAddress, label, { value: authFee1 }),
    ).to.emit(pnsContract, 'PhoneRecordCreated');
  });

  it('should throw error when creating a record with an existing phone', async function () {
    await expect(
      pnsContract.setPhoneRecord(phoneNumber1, adminAddress, adminAddress, label, { value: authFee1 }),
    ).to.be.revertedWith('phone record already exists');
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
