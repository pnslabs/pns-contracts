import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../utils/util');
const { deployContract } = require('../scripts/deploy');

describe('PNS Registry', () => {
  let pnsRegistryContract;
  let pnsResolverContract;
  let adminAddress;
  let balanceBeforeTx;
  const phoneNumber1 = keccak256('07084562591');
  const phoneNumber2 = keccak256('08084442592');
  const label = 'ETH';
  const status = true;
  const signer = ethers.provider.getSigner();
  const otp = '123456';

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
    await expect(pnsRegistryContract.setPhoneRecord(phoneNumber1, adminAddress, label)).to.emit(
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
    await expect(pnsRegistryContract.setPhoneRecord(phoneNumber1, adminAddress, label)).to.be.revertedWith(
      'phone record already exists',
    );
  });

  it('should verifiy that new recorded created exist', async () => {
    const phoneRecordExist = await pnsResolverContract.recordExists(phoneNumber1);

    assert.equal(phoneRecordExist, true);
  });

  it('should return false if record does not exist', async () => {
    const phoneRecordExist = await pnsRegistryContract.recordExists(phoneNumber2);

    assert.equal(phoneRecordExist, false);
  });

  it('should tie the correct owner to record', async () => {
    const phoneRecord = await pnsResolverContract.getRecord(phoneNumber1);
    assert.equal(phoneRecord.owner, adminAddress);
  });
  it('should withdraw the funds from the contract balance', async () => {
    const contractBalance = await ethers.provider.getBalance(pnsRegistryContract.address);
    await expect(pnsRegistryContract.withdraw(adminAddress, contractBalance)).to.emit(
      pnsRegistryContract,
      'WithdrawalSuccessful',
    );
    const contractBalanceAfterWitdrawal = await ethers.provider.getBalance(pnsRegistryContract.address);
  });
});
