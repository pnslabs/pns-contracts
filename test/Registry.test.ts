import { ethers } from 'hardhat';
import hre from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../utils/util');
const { deployContract } = require('../scripts/deployLocal');

describe('PNS Registry', () => {
  let pnsRegistryContract;
  let pnsResolverContract;
  let adminAddress;
  let balanceBeforeTx;
  const phoneNumber1 = keccak256('07084562591');
  const phoneNumber2 = keccak256('08084442592');
  const oneYearInSeconds = 31536000;
  const twoYearsInSeconds = 63072000;
  const thirtyDaysInSeconds = 2592000;
  const label = 'ETH';
  const label2 = 'BTC';
  const status = true;
  const signer = ethers.provider.getSigner();
  const otp = '123456';
  let amountInETH;
  let amount = '10000000000000000000';
  let renewAmount = '5000000000000000000';
  let newSigner;

  let message = ethers.utils.solidityPack(['bytes32', 'uint256'], [phoneNumber1, otp]);
  const hashedMessage = ethers.utils.keccak256(message);
  let signature;

  before(async function () {
    signature = await signer.signMessage(ethers.utils.arrayify(hashedMessage));
    const {
      pnsRegistryContract: _pnsRegistryContract,
      adminAddress: _adminAddress,
      pnsResolverContract: _pnsResolverContract,
    } = await deployContract();
    pnsRegistryContract = _pnsRegistryContract;
    adminAddress = _adminAddress;
    pnsResolverContract = _pnsResolverContract;
  });

  it('should verify the phone number', async () => {
    balanceBeforeTx = await ethers.provider.getBalance(adminAddress);
    console.log(balanceBeforeTx, 'balance before tx');

    await expect(pnsRegistryContract.verifyPhone(phoneNumber1, hashedMessage, status, signature)).to.emit(
      pnsRegistryContract,
      'PhoneNumberVerified',
    );
  });
  it('should create a new record', async function () {
    amountInETH = await pnsRegistryContract.getAmountinETH(amount);
    await expect(pnsRegistryContract.setPhoneRecord(phoneNumber1, adminAddress, label, { value: amountInETH })).to.emit(
      pnsRegistryContract,
      'PhoneRecordCreated',
    );
  });
  it('should verify that the right amount was deducted from the owner', async function () {
    let balanceAfterTX = await ethers.provider.getBalance(adminAddress);

    await expect(
      balanceAfterTX < balanceBeforeTx,
      'balance after transaction should be less than balance before transaction',
    );

    console.log(balanceAfterTX, 'balance after tx');
  });

  it('should throw error when creating a record with an existing phone', async function () {
    amountInETH = await pnsRegistryContract.getAmountinETH(amount);
    await expect(
      pnsRegistryContract.setPhoneRecord(phoneNumber1, adminAddress, label, { value: amountInETH }),
    ).to.be.revertedWith('phone record has been created and linked to a wallet already');
  });

  it('should verifiy that new recorded created exist', async () => {
    const phoneRecordExist = await pnsRegistryContract.recordExists(phoneNumber1);

    assert.equal(phoneRecordExist, true);
  });

  it('should return false if record does not exist', async () => {
    const phoneRecordExist = await pnsRegistryContract.recordExists(phoneNumber2);

    assert.equal(phoneRecordExist, false);
  });

  it('should tie the correct owner to record', async () => {
    const owner = await pnsResolverContract.getOwner(phoneNumber1);
    assert.equal(owner, adminAddress);
  });
  it('should withdraw the funds from the contract balance', async () => {
    const contractBalance = await ethers.provider.getBalance(pnsRegistryContract.address);
    console.log(contractBalance, 'contract balance before withdrawal');
    await expect(pnsRegistryContract.withdraw(adminAddress, contractBalance)).to.emit(
      pnsRegistryContract,
      'WithdrawalSuccessful',
    );
    const contractBalanceAfterWitdrawal = await ethers.provider.getBalance(pnsRegistryContract.address);
    console.log(contractBalanceAfterWitdrawal, 'contract balance after withdrawal');
  });
  it('admin can set a new expiry time and it emits the expected event', async () => {
    await expect(pnsRegistryContract.setExpiryTime(twoYearsInSeconds)).to.emit(
      pnsRegistryContract,
      'ExpiryTimeUpdated',
    );
  });

  it('admin can set a new grace period and it emits the expected event', async () => {
    await expect(pnsRegistryContract.setGracePeriod(thirtyDaysInSeconds)).to.emit(
      pnsRegistryContract,
      'GracePeriodUpdated',
    );
  });

  it('gets returns the expiration time of the phone record', async () => {
    const phoneRecord = await pnsRegistryContract.getRecord(phoneNumber1);
    console.log(phoneRecord, 'phone record from the resolver');
    expect(Number(phoneRecord[7])).to.be.greaterThan(0);
  });

  it('reverts with an error when attempting to renew a phone record that is not in grace period', async () => {
    let renewAmountInETH = await pnsRegistryContract.getAmountinETH(renewAmount);
    await expect(pnsRegistryContract.renew(phoneNumber1, { value: renewAmountInETH })).to.be.revertedWith(
      'only a phone record currently in grace period can be renewed',
    );
  });

  it('increases the evm time to be in grace period, while expiration status remains false', async () => {
    await network.provider.send('evm_increaseTime', [oneYearInSeconds]);
    await network.provider.send('evm_mine', []);
    const getRecord = await pnsRegistryContract.getRecord(phoneNumber1);
    console.log(getRecord[4], getRecord[5], 'get record');
    expect(getRecord[4]).to.equal(true);
    expect(getRecord[5]).to.equal(false);
  });

  it('successfully renews an unexpired phone record that is in grace period, and emits an event', async () => {
    let renewAmountInETH = await pnsRegistryContract.getAmountinETH(renewAmount);
    await expect(pnsRegistryContract.renew(phoneNumber1, { value: renewAmountInETH })).to.emit(
      pnsRegistryContract,
      'PhoneRecordRenewed',
    );
  });

  it('reverts with an error when attempting to claim an unexpired phone record', async () => {
    await expect(pnsRegistryContract.claimExpiredPhoneRecord(phoneNumber1, adminAddress, label)).to.be.revertedWith(
      'only an expired phone record can be claimed',
    );
  });

  it('increases the evm time until it exceeds the phone record expiration time', async () => {
    await network.provider.send('evm_increaseTime', [twoYearsInSeconds + thirtyDaysInSeconds + 1]);
    await network.provider.send('evm_mine', []);
    const getRecord = await pnsRegistryContract.getRecord(phoneNumber1);
    expect(getRecord[4]).to.equal(true);
    expect(getRecord[5]).to.equal(true);
  });

  // it('successfully claims an expired phone record, and emits an event', async () => {
  //   const signer = new ethers.Wallet(
  //     '0xd59a17e80bf71a938d875e5ad030a5caadc41f28863562fce69435a2d150f02c',
  //     hre.network.provider,
  //   );
  //   newSigner = signer.address;
  //   await expect(pnsRegistryContract.connect(signer).claimExpiredPhoneRecord(phoneNumber1, address, label2)).to.emit(
  //     pnsRegistryContract,
  //     'PhoneRecordCreated',
  //   );
  // });

  // it('successfully deletes the previous record, and sets a new one when record is claimed.', async () => {
  //   const resolvers = await pnsResolverContract.getResolverDetails(phoneNumber1);
  //   const wallets = resolvers.length;
  //   const label = resolvers[0][2];

  //   assert.equal(wallets, 1);
  //   assert.equal(label, label2);
  // });
});
