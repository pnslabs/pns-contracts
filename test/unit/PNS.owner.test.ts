import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../../utils/util');
const { deployContract } = require('../../scripts/deploy-helpers');

describe('PNS Record Owner', () => {
  let pnsContract;
  let pnsGuardianContract;
  let adminAddress;
  const phoneNumber = keccak256('07084462591');
  const label = 'ETH';
  const address = '0xcD058D84F922450591AD59303AA2B4A864da19e6';

  const status = true;
  const signer = ethers.provider.getSigner();
  const otp = '123456';

  let message = ethers.utils.solidityPack(['bytes32', 'uint256'], [phoneNumber, otp]);
  const hashedMessage = ethers.utils.keccak256(message);
  let signature;

  before(async function () {
    signature = await signer.signMessage(ethers.utils.arrayify(hashedMessage));
    const {
      pnsContract: _pnsContract,
      adminAddress: _adminAddress,
      pnsGuardianContract: _pnsGuardianContract,
    } = await deployContract();
    pnsContract = _pnsContract;
    adminAddress = _adminAddress;
    pnsGuardianContract = _pnsGuardianContract;
  });

  it('should verify the phone number', async () => {
    await expect(pnsGuardianContract.setVerificationStatus(phoneNumber, hashedMessage, status, signature)).to.emit(
      pnsGuardianContract,
      'PhoneVerified',
    );
  });

  it('should create a new record and emit an event', async function () {
    await expect(pnsContract.setPhoneRecord(phoneNumber, adminAddress, label)).to.emit(
      pnsContract,
      'PhoneRecordCreated',
    );
  });

  it('gets the correct owner of the record', async () => {
    const recordOwner = await pnsContract.getOwner(phoneNumber);

    assert.equal(recordOwner, adminAddress);
  });

  it('changes record owner and emits an event', async () => {
    await expect(
      pnsContract.setOwner(phoneNumber, address),
    ).to.emit(pnsContract, 'Transfer');
  });

  it('gets newly transfered record owner', async () => {
    const recordOwner = await pnsContract.getOwner(phoneNumber);
    assert.equal(recordOwner, address);
  });
});
