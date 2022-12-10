import { network, ethers } from 'hardhat';

const { expect, assert } = require('chai');
const { keccak256 } = require('../../utils/util');
const { deployContract } = require('../../scripts/deploy');

describe('PNS Expire', () => {
  let pnsRegistryContract;
  let adminAddress;
  let pnsGuardianContract;
  const phoneNumber = keccak256('07084462591');
  const label1 = 'ETH';
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
    } = await deployContract();
    pnsRegistryContract = _pnsGuardianContract;
    adminAddress = _adminAddress;
    pnsGuardianContract = _pnsGuardianContract;
  });

  it('reverts with an error when attempting to set a phone record that is not verified', async () => {
    await expect(pnsRegistryContract.setPhoneRecord(phoneNumber, adminAddress, label1)).to.be.revertedWith(
      'phone record is not verified',
    );
  });

  it('should verify the phone number', async () => {
    await expect(pnsGuardianContract.setVerificationStatus(phoneNumber, hashedMessage, status, signature)).to.emit(
      pnsGuardianContract,
      'PhoneVerified',
    );
  });

  it('should get the correct verification status', async () => {
    const status = await pnsGuardianContract.getVerificationStatus(phoneNumber);
    expect(status).to.equal(true);
  });
});
