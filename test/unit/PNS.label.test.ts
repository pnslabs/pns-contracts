import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { keccak256: _keccak256 } = require('../../utils/util');

describe('PNS Label linking', () => {
  let adminAccount;
  let pnsContract;
  let adminAddress;
  const phoneNumber1 = _keccak256('07084462591');
  const phoneNumber2 = _keccak256('08084442592');
  const label1 = 'ETH';
  const label2 = 'BTC';
  let resolverCreatedLength = 0;

  before(async function () {
    [adminAccount] = await ethers.getSigners();
    adminAddress = adminAccount.address;

    const PNSContract = await ethers.getContractFactory('PNS');

    pnsContract = await PNSContract.deploy();
  });

  // will come back to this

  // it('should throw an error if an unauthorized user tries to add a new resolver', async () => {
  //   await expect(
  //     pnsContract.linkPhoneToWallet(phoneNumber1, adminAddress, label2, {
  //       from: address1,
  //     }),
  //   ).to.be.revertedWith('caller is not authorised');
  // });

  it('should create a new record and emit an event', async function () {
    await expect(pnsContract.setPhoneRecord(phoneNumber1, adminAddress, adminAddress, label1)).to.emit(
      pnsContract,
      'PhoneRecordCreated',
    );
    resolverCreatedLength++;
  });

  it('should link a new resolver to a phone record and emit an event', async () => {
    await expect(pnsContract.linkPhoneToWallet(phoneNumber1, adminAddress, label2)).to.emit(pnsContract, 'PhoneLinked');
    resolverCreatedLength++;
  });

  it('verifies that all previously created resolvers exists', async () => {
    const resolvers = await pnsContract.getResolverDetails(phoneNumber1);
    const wallets = resolvers.length;

    assert.equal(wallets, resolverCreatedLength);
  });

  it('should throw an error if phone record of a resolver does not exist', async () => {
    await expect(pnsContract.getResolverDetails(phoneNumber2)).to.be.revertedWith('phone record not found');
  });

  it('should get the details of a specific resolver', async () => {
    const resolvers = await pnsContract.getResolverDetails(phoneNumber1);
    const firstLabel = resolvers[0][2];
    const secondLabel = resolvers[1][2];

    assert.equal(firstLabel, label1);
    assert.equal(secondLabel, label2);
  });
});
