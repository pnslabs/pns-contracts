import { ethers } from 'hardhat';

async function deployContract() {
  let adminAccount;

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;

  const PNSContract = await ethers.getContractFactory('PNS');

  const pnsContract = await PNSContract.deploy();

  return { pnsContract, adminAddress };
}

module.exports = {
  deployContract,
};
