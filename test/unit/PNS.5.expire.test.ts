import { network } from 'hardhat';

const { expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Expire', () => {
  const { oneYearInSeconds, thirtyDaysInSeconds, phoneNumber1, label1, twoYearsInSeconds, address3 } = testVariables;

  it('reverts with an error when attempting to reAuthenticate a phone record that is not in grace period', async () => {
    await expect(testVariables.pnsContract.reAuthenticate(phoneNumber1)).to.be.revertedWith(
      'only a phone record currently in grace period can be re-authenticated',
    );
  });

  it('increases the evm time to be in grace period, while expiration status remains false', async () => {
    await network.provider.send('evm_increaseTime', [oneYearInSeconds]);
    await network.provider.send('evm_mine', []);
    const getRecord = await testVariables.pnsContract.getRecord(testVariables.phoneNumber1);
    expect(getRecord[5]).to.equal(true);
    expect(getRecord[6]).to.equal(false);
  });

  it('successfully reAuthenticates an unexpired phone record that is in grace period, and emits an event', async () => {
    await expect(testVariables.pnsContract.reAuthenticate(phoneNumber1)).to.emit(
      testVariables.pnsContract,
      'PhoneRecordAuthenticated',
    );
  });

  it('reverts with an error when attempting to claim an unexpired phone record', async () => {
    await expect(
      testVariables.pnsContract.claimExpiredPhoneRecord(
        phoneNumber1,
        testVariables.adminAddress,
        testVariables.adminAddress,
        label1,
      ),
    ).to.be.revertedWith('only an expired phone record can be claimed');
  });

  it('increases the evm time until it exceeds the phone record expiration time', async () => {
    await network.provider.send('evm_increaseTime', [twoYearsInSeconds + thirtyDaysInSeconds + 1]);
    await network.provider.send('evm_mine', []);
    const getRecord = await testVariables.pnsContract.getRecord(testVariables.phoneNumber1);
    expect(getRecord[5]).to.equal(true);
    expect(getRecord[6]).to.equal(true);
  });

  it('successfully claims an expired phone record, and emits an event', async () => {
    await expect(testVariables.pnsContract.claimExpiredPhoneRecord(phoneNumber1, address3, address3, label1)).to.emit(
      testVariables.pnsContract,
      'PhoneRecordClaimed',
    );
  });
});
