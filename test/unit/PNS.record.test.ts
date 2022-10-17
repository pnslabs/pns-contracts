import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256: _keccak256 } = require('../../utils/util');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Record', () => {
  let pnsContract;
  let adminAddress;
  const phoneNumber1 = _keccak256('07084462591');
  const phoneNumber2 = _keccak256('08084442592');
  const label = 'ETH';

  before(() => {
    adminAddress = testVariables.adminAddress;
    pnsContract = testVariables.pnsContract;
  });

  it('should throw error when creating a record with an existing phone', async function () {
    await expect(pnsContract.setPhoneRecord(phoneNumber1, adminAddress, adminAddress, label)).to.be.revertedWith(
      'phone record already exists',
    );
  });

  it('verifies that new record created exist', async () => {
    const phoneRecordExist = await pnsContract.recordExists(phoneNumber1);

    assert.equal(phoneRecordExist, true);
  });

  it('should return false if record does not exist', async () => {
    const phoneRecordExist = await pnsContract.recordExists(phoneNumber2);

    assert.equal(phoneRecordExist, false);
  });
});
