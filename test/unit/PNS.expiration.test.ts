import { network, ethers } from 'hardhat';

const { expect, assert } = require('chai');
const { keccak256 } = require('../../utils/util');
const { deployContract } = require('../../scripts/deploy-helpers');

describe('PNS Expire', () => {
  let pnsContract;
  let adminAddress;
  const phoneNumber = keccak256('07084462591');
  const oneYearInSeconds = 31536000;
  const twoYearsInSeconds = 63072000;
  const thirtyDaysInSeconds = 2592000;
  const label1 = 'ETH';
  const label2 = 'BTC';
  const address = '0xcD058D84F922450591AD59303AA2B4A864da19e6';

  before(async function () {
    const { pnsContract: _pnsContract, adminAddress: _adminAddress } = await deployContract();
    pnsContract = _pnsContract;
    adminAddress = _adminAddress;
  });

  it('should create a new record and emit an event', async function () {
    await expect(pnsContract.setPhoneRecord(phoneNumber, adminAddress, adminAddress, label1)).to.emit(
      pnsContract,
      'PhoneRecordCreated',
    );
  });

  it('admin can set a new expiry time and it emits the expected event', async () => {
    await expect(pnsContract.setNewExpiryTime(twoYearsInSeconds)).to.emit(pnsContract, 'ExpiryTimeUpdated');
  });

  it('admin can set a new grace period and it emits the expected event', async () => {
    await expect(pnsContract.setNewGracePeriod(thirtyDaysInSeconds)).to.emit(pnsContract, 'GracePeriodUpdated');
  });

  it('gets returns the expiration time of the phone record', async () => {
    const phoneRecord = await pnsContract.getRecord(phoneNumber);
    expect(Number(phoneRecord[7])).to.be.greaterThan(0);
  });

  it('reverts with an error when attempting to reAuthenticate a phone record that is not in grace period', async () => {
    await expect(pnsContract.reAuthenticate(phoneNumber)).to.be.revertedWith(
      'only a phone record currently in grace period can be re-authenticated',
    );
  });

  it('increases the evm time to be in grace period, while expiration status remains false', async () => {
    await network.provider.send('evm_increaseTime', [oneYearInSeconds]);
    await network.provider.send('evm_mine', []);
    const getRecord = await pnsContract.getRecord(phoneNumber);
    expect(getRecord[5]).to.equal(true);
    expect(getRecord[6]).to.equal(false);
  });

  it('successfully reAuthenticates an unexpired phone record that is in grace period, and emits an event', async () => {
    await expect(pnsContract.reAuthenticate(phoneNumber)).to.emit(pnsContract, 'PhoneRecordAuthenticated');
  });

  it('reverts with an error when attempting to claim an unexpired phone record', async () => {
    await expect(
      pnsContract.claimExpiredPhoneRecord(phoneNumber, adminAddress, adminAddress, label1),
    ).to.be.revertedWith('only an expired phone record can be claimed');
  });

  it('increases the evm time until it exceeds the phone record expiration time', async () => {
    await network.provider.send('evm_increaseTime', [twoYearsInSeconds + thirtyDaysInSeconds + 1]);
    await network.provider.send('evm_mine', []);
    const getRecord = await pnsContract.getRecord(phoneNumber);
    expect(getRecord[5]).to.equal(true);
    expect(getRecord[6]).to.equal(true);
  });

  it('successfully claims an expired phone record, and emits an event', async () => {
    await expect(pnsContract.claimExpiredPhoneRecord(phoneNumber, address, address, label2)).to.emit(
      pnsContract,
      'PhoneRecordCreated',
    );
  });

  it('successfully deletes the previous record, and sets a new one when record is claimed.', async () => {
    const resolvers = await pnsContract.getResolverDetails(phoneNumber);
    const wallets = resolvers.length;
    const label = resolvers[0][2];

    assert.equal(wallets, 1);
    assert.equal(label, label2);
  });
});
