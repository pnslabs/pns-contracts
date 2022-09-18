const { keccak256 } = require("../scripts/util");
const PNS = artifacts.require("PNS");
const ProxyAdmin = artifacts.require("ProxyAdmin");
const TransparentUpgradeableProxy = artifacts.require(
  "TransparentUpgradeableProxy",
);

const Web3 = require("web3");
const web3 = new Web3("http://localhost:8545");

contract("PNS", () => {
  let pnsContract = null;
  let proxyAdminContract = null;
  let transparentUpgradeableProxyContract = null;
  let adminAccount;
  let normalAccount;
  let resolverAccount;
  let accounts;
  let phoneNumber = keccak256("07084462591");

  before(async function () {
    console.log(web3.eth);
    accounts = await web3.eth.getAccounts();
    adminAccount = accounts[0];
    normalAccount = accounts[1];
    resolverAccount = accounts[2];
    pnsContract = await PNS.new();
    proxyAdminContract = await ProxyAdmin.new();
    transparentUpgradeableProxyContract =
      await TransparentUpgradeableProxy.new();
  });

  it("should create a phone record", async function () {
    const phoneRecordTX = await transparentUpgradeableProxyContract(
      pnsContract.address,
    ).setPhoneRecord(phoneNumber, normalAccount, resolverAccount, "eth", {
      from: normalAccount,
    });
    console.log(phoneRecordTX, "phoneRecord");
  });
});
