const PNS = artifacts.require("PNS");
const ProxyAdmin = artifacts.require("ProxyAdmin");
const TransparentUpgradeableProxy = artifacts.require(
  "TransparentUpgradeableProxy",
);


contract("PNS", () => {
    const [owner] = await ethers.getSigners();

    let pnsContract = null;
    let proxyAdminContract = null;
    let transparentUpgradeableProxyContract = null;


})
