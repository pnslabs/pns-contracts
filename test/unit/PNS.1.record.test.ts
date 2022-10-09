import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Record', () => {
  const { phoneNumber1, phoneNumber2, label1 } = testVariables;

  it('should create a new record and emit an event', async function () {
    await expect(
      testVariables.pnsContract.setPhoneRecord(
        phoneNumber1,
        testVariables.adminAddress,
        testVariables.adminAddress,
        label1,
      ),
    ).to.emit(testVariables.pnsContract, 'PhoneRecordCreated');

    testVariables.resolverCreatedLength++;
  });

  it('should throw error when creating a record with an existing phone', async function () {
    await expect(
      testVariables.pnsContract.setPhoneRecord(
        phoneNumber1,
        testVariables.adminAddress,
        testVariables.adminAddress,
        label1,
      ),
    ).to.be.revertedWith('phone record already exists');
  });

  it('verifies that new recorded created exist', async () => {
    const phoneRecordExist = await testVariables.pnsContract.recordExists(phoneNumber1);

    assert.equal(phoneRecordExist, true);
  });

  it('should return false if record does not exist', async () => {
    const phoneRecordExist = await testVariables.pnsContract.recordExists(phoneNumber2);

    assert.equal(phoneRecordExist, false);
  });

  it('ties the correct owner to record', async () => {
    const phoneRecord = await testVariables.pnsContract.getRecord(phoneNumber1);
    assert.equal(phoneRecord.owner, testVariables.adminAddress);
  });
});
