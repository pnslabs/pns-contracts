import { ethers } from 'hardhat';

const { assert, expect } = require('chai');
const { web3 } = require('web3');
const { keccak256 } = require('../scripts/util');

describe('PNS', () => {
  let pnsContract = null;
  let proxyAdminContract = null;
  let transparentUpgradeableProxyContract = null;
  let adminAccount;
  let normalAccount = '0xf34f20B517D589A3a4847FE0d98762638e64E594';
  let resolverAccount;
  let accounts;
  let phoneNumber = keccak256('07084462591');
  let phoneNumber2 = keccak256('07284462591');
  let label1 = 'ETH';
  let label2 = 'BTC';
  let resolverCreatedLength = 0;

  before(async function () {
    [adminAccount] = await ethers.getSigners();

    const PNSContract = await ethers.getContractFactory('PNS');
    const ProxyAdminContract = await ethers.getContractFactory('ProxyAdmin');
    const TransparentUpgradeableProxyContract = await ethers.getContractFactory('TransparentUpgradeableProxy');

    pnsContract = await PNSContract.deploy();
    proxyAdminContract = await ProxyAdminContract.deploy();
    const encodedData = ethers.utils.hexlify('0x');

    transparentUpgradeableProxyContract = await TransparentUpgradeableProxyContract.deploy(
      pnsContract.address,
      proxyAdminContract.address,
      encodedData,
    );
  });

  describe('Record::', () => {
    it('should create a new record', async function () {
      await expect(pnsContract.setPhoneRecord(phoneNumber, adminAccount.address, adminAccount.address, label1)).to.not
        .be.reverted;
      resolverCreatedLength++;
    });

    it('verifies that new recorded created exist', async () => {
      const phoneRecordExist = await pnsContract.recordExists(phoneNumber);

      assert.equal(phoneRecordExist, true);
    });

    it('ties the correct owner to record', async () => {
      const phoneRecord = await pnsContract.getRecord(phoneNumber);
      assert.equal(phoneRecord.owner, adminAccount.address);
    });
  });

  describe('Label linking::', () => {
    //misleading test
    it('verifies that new recorded created exist', async () => {
      await expect(pnsContract.linkPhoneToWallet(phoneNumber, adminAccount.address, label2)).to.not.be.reverted;
      resolverCreatedLength++;
    });

    it('verifies that all currently created resolvers are available', async () => {
      const resolvers = await pnsContract.getResolverDetails(phoneNumber);
      const wallets = resolvers.length;

      assert.equal(wallets, resolverCreatedLength);
    });

    it('verifies that labels are correct', async () => {
      const resolvers = await pnsContract.getResolverDetails(phoneNumber);
      const firstLabel = resolvers[0][2];
      const secondLabel = resolvers[1][2];

      assert.equal(firstLabel, label1);
      assert.equal(secondLabel, label2);
    });
  });

  describe('Owner::', () => {
    it('gets the correct owner of the record', async () => {
      const recordOwner = await pnsContract.getOwner(phoneNumber);

      assert.equal(recordOwner, adminAccount.address);
    });

    it('changes record owner', async () => {
      await expect(pnsContract.connect(adminAccount).setOwner(phoneNumber, normalAccount)).to.not.be.reverted;
    });

    it('gets new record owner', async () => {
      const recordOwner = await pnsContract.getOwner(phoneNumber);
      assert.equal(recordOwner, normalAccount);
    });
  });

  describe('Expiration::', () => {
    it('gets returns the expiration time of the phone record', async () => {
      const phoneRecord = await pnsContract.getRecord(phoneNumber);

      expect(Number(phoneRecord[7])).to.be.greaterThan(0);
    });
  });
});
