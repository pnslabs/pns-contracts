const { assert, expect } = require("chai");
const { web3 } = require("hardhat");
const { keccak256 } = require("../scripts/util");
const PNS = artifacts.require("PNS");
const ProxyAdmin = artifacts.require("ProxyAdmin");
const TransparentUpgradeableProxy = artifacts.require(
  "TransparentUpgradeableProxy"
);
contract("PNS", () => {
  let pnsContract = null;
  let proxyAdminContract = null;
  let transparentUpgradeableProxyContract = null;
  let adminAccount;
  let normalAccount = "0xf34f20B517D589A3a4847FE0d98762638e64E594";
  let resolverAccount;
  let accounts;
  let phoneNumber = keccak256("07084462591");
  let label1 = "eth";
  let label2 = "bitcoin";
  let resolverCreatedLength = 0;

  before(async function () {
    accounts = await web3.eth.getAccounts();
    console.log(accounts, "account");
    adminAccount = accounts[0];

    const encodedData = web3.utils.hexToBytes("0x");

    pnsContract = await PNS.new();
    proxyAdminContract = await ProxyAdmin.new();
    console.log(proxyAdminContract.address, "proxy address");
    transparentUpgradeableProxyContract = await TransparentUpgradeableProxy.new(
      pnsContract.address,
      proxyAdminContract.address,
      encodedData
    );
  });

  describe("Record::", () => {
    it("should create a new record", async function () {
      const phoneRecordTX = await pnsContract.setPhoneRecord(
        phoneNumber,
        adminAccount,
        adminAccount,
        label1
      );
      resolverCreatedLength++;
      assert(
        phoneRecordTX.receipt.status == true,
        "phone record created successfully"
      );
    });

    it("verifies that new recorded created exist", async () => {
      const phoneRecordExist = await pnsContract.recordExists(phoneNumber);

      assert.equal(phoneRecordExist, true);
    });

    it("ties the correct owner to record", async () => {
      const phoneRecord = await pnsContract.getRecord(phoneNumber);

      assert.equal(phoneRecord.owner, adminAccount);
    });
  });

  describe("Label linking::", () => {
    it("verifies that new recorded created exist", async () => {
      const phoneRecord = await pnsContract.linkPhoneToWallet(
        phoneNumber,
        adminAccount,
        label2
      );
      resolverCreatedLength++;

      assert.equal(phoneRecord.receipt.status, true);
    });

    it("verifies that all currently created resolvers are available", async () => {
      const resolvers = await pnsContract.getResolverDetails(phoneNumber);
      const wallets = resolvers.length;

      assert.equal(wallets, resolverCreatedLength);
    });

    it("verifies that labels are correct", async () => {
      const resolvers = await pnsContract.getResolverDetails(phoneNumber);
      const firstLabel = resolvers[0][2];
      const secondLabel = resolvers[1][2];

      assert.equal(firstLabel, label1);
      assert.equal(secondLabel, label2);
    });
  });

  describe("Owner::", () => {
    it("gets the correct owner of the record", async () => {
      const recordOwner = await pnsContract.getOwner(phoneNumber);

      assert.equal(recordOwner, adminAccount);
    });

    it("changes record owner", async () => {
      const recordOwner = await pnsContract.setOwner(
        phoneNumber,
        normalAccount
      );

      assert.equal(recordOwner.receipt.status, true);
    });

    it("gets new record owner", async () => {
      const recordOwner = await pnsContract.getOwner(phoneNumber);

      assert.equal(recordOwner, normalAccount);
    });
  });
});
