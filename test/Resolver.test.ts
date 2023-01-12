import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256 } = require('../utils/util');
const { deployContract } = require('../scripts/deployLocal');

describe('PNS Resolver', () => {
  let pnsRegistryContract;
  let pnsResolverContract;
  let adminAddress;
  const phoneNumber1 = keccak256('07084462591');
  const phoneNumber2 = keccak256('08084442592');
  const label1 = 'ETH';
  const label2 = 'BTC';
  let resolverCreatedLength = 0;
  let balanceBeforeTx;
  const status = true;
  const signer = ethers.provider.getSigner();
  const otp = '123456';
  let amountInETH;
  let amount = '10000000000000000000';

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
    pnsResolverContract = _pnsResolverContract;
    adminAddress = _adminAddress;
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
    await expect(
      pnsRegistryContract.setPhoneRecord(phoneNumber1, adminAddress, label1, { value: amountInETH }),
    ).to.emit(pnsRegistryContract, 'PhoneRecordCreated');
    resolverCreatedLength++;
  });

  it('should link a new resolver to a phone record and emit an event', async () => {
    await expect(pnsRegistryContract.linkPhoneToWallet(phoneNumber1, adminAddress, label2)).to.emit(
      pnsRegistryContract,
      'PhoneLinked',
    );
    resolverCreatedLength++;
  });

  it('verifies that all previously created resolvers exists', async () => {
    const resolvers = await pnsResolverContract.getResolverDetails(phoneNumber1);
    console.log(resolvers.length, 'resolver length');
    console.log(resolverCreatedLength, 'length of resolvers created');
    const wallets = resolvers.length;

    assert.equal(wallets, resolverCreatedLength);
  });

  it('should get the details of a specific resolver', async () => {
    const resolvers = await pnsResolverContract.getResolverDetails(phoneNumber1);
    const firstLabel = resolvers[0][2];
    const secondLabel = resolvers[1][2];

    console.log(resolvers, 'resolvers');

    assert.equal(firstLabel, label1);
    assert.equal(secondLabel, label2);
  });
});
