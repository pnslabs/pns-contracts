const { web3 } = require("hardhat");
const { keccak256 } = require("../scripts/util");
const PNS = artifacts.require("PNS");
const ProxyAdmin = artifacts.require("ProxyAdmin");
const TransparentUpgradeableProxy = artifacts.require(
  "TransparentUpgradeableProxy",
);
contract("PNS", () => {
  let pnsContract = null;
  let proxyAdminContract = null;
  let transparentUpgradeableProxyContract = null;
  let adminAccount;
  let normalAccount;
  let resolverAccount;
  let accounts;
  let phoneNumber = keccak256("07084462591");
  console.log(phoneNumber, "phone number");

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
      encodedData,
    );
  });

  it("should create a phone record", async function () {
    console.log(resolverAccount, "resolver account");
    const phoneRecordTX = await pnsContract.setPhoneRecord(
      phoneNumber,
      adminAccount,
      adminAccount,
      "eth",
    );
    console.log(phoneRecordTX, "phoneRecord");
  });
  it("should get record", async function () {
    const recordTX = await pnsContract.getRecord(phoneNumber);
    console.log(recordTX, "record tx");
    // console.log(
    //   `resolver address ${recordTX[0]}`,
    //   `time created ${recordTX[1]}`,
    //   `resolver label ${recordTX[2]}`,
    //   `record exists ${recordTX[3]}`,
    // );
  });
});
