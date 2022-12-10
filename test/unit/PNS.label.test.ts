import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../../utils/util');
const { deployContract } = require('../../scripts/deploy');

describe('PNS Label linking', () => {
  let pnsRegistryContract;
  let pnsResolverContract;
  let adminAddress;
  let pnsGuardianContract;
  const phoneNumber1 = keccak256('07084462591');
  const phoneNumber2 = keccak256('08084442592');
  const label1 = 'ETH';
  const label2 = 'BTC';
  let resolverCreatedLength = 0;
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
      pnsGuardianContract: _pnsGuardianContract,
      pnsResolverContract: _pnsResolverContract,
    } = await deployContract();
    pnsRegistryContract = _pnsRegistryContract;
    pnsResolverContract = _pnsResolverContract;
    adminAddress = _adminAddress;
    pnsGuardianContract = _pnsGuardianContract;
  });

  // will come back to this

  // it('should throw an error if an unauthorized user tries to add a new resolver', async () => {
  //   await expect(
  //     pnsContract.linkPhoneToWallet(phoneNumber1, adminAddress, label2, {
  //       from: address1,
  //     }),
  //   ).to.be.revertedWith('caller is not authorised');
  // });
  it('should verify the phone number', async () => {
    await expect(pnsRegistryContract.setVerificationStatus(phoneNumber1, hashedMessage, status, signature)).to.emit(
      pnsGuardianContract,
      'PhoneVerified',
    );
  });

  it('should create a new record and emit an event', async function () {
    await expect(pnsRegistryContract.setPhoneRecord(phoneNumber1, adminAddress, label1)).to.emit(
      pnsRegistryContract,
      'PhoneRecordCreated',
    );
    resolverCreatedLength++;
  });

  it('should link a new resolver to a phone record and emit an event', async () => {
    await expect(pnsRegistryContract.linkPhoneToWallet(phoneNumber1, adminAddress, label2)).to.emit(pnsRegistryContract, 'PhoneLinked');
    resolverCreatedLength++;
  });

  it('verifies that all previously created resolvers exists', async () => {
    const resolvers = await pnsResolverContract.getResolverDetails(phoneNumber1);
    const wallets = resolvers.length;

    assert.equal(wallets, resolverCreatedLength);
  });

  it('should throw an error if phone record of a resolver does not exist', async () => {
    await expect(pnsResolverContract.getResolverDetails(phoneNumber2)).to.be.revertedWith('phone record not found');
  });

  it('should get the details of a specific resolver', async () => {
    const resolvers = await pnsResolverContract.getResolverDetails(phoneNumber1);
    const firstLabel = resolvers[0][2];
    const secondLabel = resolvers[1][2];

    assert.equal(firstLabel, label1);
    assert.equal(secondLabel, label2);
  });
});
