import { network } from 'hardhat';

const { expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Admin', () => {
  const { address1, zeroAddress } = testVariables;
  const twoYearsInSeconds = 63072000;
  const thirtyDaysInSeconds = 2592000;

  it('reverts with an error when attempting to add an admin that already exists', async () => {
    await expect(testVariables.pnsContract.addAdmin(testVariables.adminAddress)).to.be.revertedWith(
      'admin already exists',
    );
  });

  it('reverts with an error when attempting to add an admin with a zero address', async () => {
    await expect(testVariables.pnsContract.addAdmin(zeroAddress)).to.be.revertedWith(
      'cannot add zero address as admin',
    );
  });

  it('adds a new admin and emits event', async () => {
    await expect(testVariables.pnsContract.addAdmin(address1)).to.emit(testVariables.pnsContract, 'AdminAdded');
  });

  it('gets the newly added admin', async () => {
    const admin = await testVariables.pnsContract.getAdmin(address1);
    expect(admin[2]).to.equal(true);
  });

  it('admin can set a new expiry time and it emits the expected event', async () => {
    await expect(testVariables.pnsContract.setNewExpiryTime(twoYearsInSeconds)).to.emit(
      testVariables.pnsContract,
      'ExpiryTimeUpdated',
    );
  });

  it('returns newly updated expiry time', async () => {
    const expiryTime = await testVariables.pnsContract.getExpiryTime();
    expect(expiryTime).to.equal(twoYearsInSeconds);
  });

  it('admin can set a new grace period and it emits the expected event', async () => {
    await expect(testVariables.pnsContract.setNewGracePeriod(thirtyDaysInSeconds)).to.emit(
      testVariables.pnsContract,
      'GracePeriodUpdated',
    );
  });

  it('returns newly updated grace period', async () => {
    const gracePeriod = await testVariables.pnsContract.getGracePeriod();
    expect(gracePeriod).to.equal(thirtyDaysInSeconds);
  });
});
