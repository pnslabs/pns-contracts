import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Record', () => {
  let adminAccount;
  const { phoneNumber1, phoneNumber2, label1 } = testVariables;

  before(async function () {
    [adminAccount] = await ethers.getSigners();
    testVariables.signer1 = adminAccount;
    testVariables.adminAddress = adminAccount.address;

    const PNSContract = await ethers.getContractFactory('PNS');

    testVariables.pnsContract = await PNSContract.deploy();
  });

  it('should create a new record', async function () {
    await expect(
      testVariables.pnsContract.setPhoneRecord(
        phoneNumber1,
        testVariables.adminAddress,
        testVariables.adminAddress,
        label1,
      ),
    ).to.not.be.reverted;

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
