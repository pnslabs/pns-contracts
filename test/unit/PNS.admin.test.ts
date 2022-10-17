import { ethers } from 'hardhat';

const { expect } = require('chai');
const { deployContract } = require('../../helper-hardhat-config');

describe('PNS Admin', () => {
  let pnsContract;
  let adminAddress;
  const newAdmin = '0xcD058D84F922450591AD59303AA2B4A864da19e6';
  const zeroAddress = '0x0000000000000000000000000000000000000000';
  const twoYearsInSeconds = 63072000;
  const thirtyDaysInSeconds = 2592000;

  before(async function () {
    const { pnsContract: _pnsContract, adminAddress: _adminAddress } = await deployContract();
    pnsContract = _pnsContract;
    adminAddress = _adminAddress;
  });

  it('reverts with an error when attempting to add an admin that already exists', async () => {
    await expect(pnsContract.addAdmin(adminAddress)).to.be.revertedWith('admin already exists');
  });

  it('reverts with an error when attempting to add an admin with a zero address', async () => {
    await expect(pnsContract.addAdmin(zeroAddress)).to.be.revertedWith('cannot add zero address as admin');
  });

  it('adds a new admin and emits event', async () => {
    await expect(pnsContract.addAdmin(newAdmin)).to.emit(pnsContract, 'AdminAdded');
  });

  it('gets the newly added admin', async () => {
    const admin = await pnsContract.getAdmin(newAdmin);
    expect(admin[2]).to.equal(true);
  });

  it('admin can set a new expiry time and it emits the expected event', async () => {
    await expect(pnsContract.setNewExpiryTime(twoYearsInSeconds)).to.emit(pnsContract, 'ExpiryTimeUpdated');
  });

  it('returns newly updated expiry time', async () => {
    const expiryTime = await pnsContract.getExpiryTime();
    expect(expiryTime).to.equal(twoYearsInSeconds);
  });

  it('admin can set a new grace period and it emits the expected event', async () => {
    await expect(pnsContract.setNewGracePeriod(thirtyDaysInSeconds)).to.emit(pnsContract, 'GracePeriodUpdated');
  });

  it('returns newly updated grace period', async () => {
    const gracePeriod = await pnsContract.getGracePeriod();
    expect(gracePeriod).to.equal(thirtyDaysInSeconds);
  });
});
