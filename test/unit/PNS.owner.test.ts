import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../../utils/util');
const { deployContract } = require('../../scripts/deploy');

describe('PNS Record Owner', () => {
  let pnsRegistryContract;
  let pnsResolverContract;
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
      pnsRegistryContract: _pnsRegistryContract,
      adminAddress: _adminAddress,
      pnsGuardianContract: _pnsGuardianContract,
      pnsResolverContract: _pnsResolverContract,
    } = await deployContract();
    pnsRegistryContract = _pnsRegistryContract;
    adminAddress = _adminAddress;
    pnsGuardianContract = _pnsGuardianContract;
    pnsResolverContract = _pnsResolverContract;
  });

  it('should verify the phone number', async () => {
    await expect(pnsGuardianContract.setVerificationStatus(phoneNumber, hashedMessage, status, signature)).to.emit(
      pnsGuardianContract,
      'PhoneVerified',
    );
  });

  it('should create a new record and emit an event', async function () {
    await expect(pnsRegistryContract.setPhoneRecord(phoneNumber, adminAddress, label)).to.emit(
      pnsRegistryContract,
      'PhoneRecordCreated',
    );
  });

  it('gets the correct owner of the record', async () => {
    const recordOwner = await pnsResolverContract.getOwner(phoneNumber);

    assert.equal(recordOwner, adminAddress);
  });

  it('changes record owner and emits an event', async () => {
    await expect(pnsRegistryContract.setOwner(phoneNumber, address)).to.emit(pnsRegistryContract, 'Transfer');
  });

  it('gets newly transfered record owner', async () => {
    const recordOwner = await pnsResolverContract.getOwner(phoneNumber);
    assert.equal(recordOwner, address);
  });
});
