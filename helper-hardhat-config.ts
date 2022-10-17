import { ethers, upgrades } from 'hardhat';

async function deployContract() {
  let adminAccount;

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;

  const PNSContract = await ethers.getContractFactory('PNS');

  const pnsContract = await upgrades.deployProxy(PNSContract, [], { initializer: 'initialize' });
  await pnsContract.deployed();

  return { pnsContract, adminAddress };
}

module.exports = {
  deployContract,
};
