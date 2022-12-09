import { ethers, upgrades } from 'hardhat';

async function deployContract() {
  let adminAccount;

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;

  const PNSContractRegistry = await ethers.getContractFactory('PNSRegistry');

  const PNSGuardianContract = await ethers.getContractFactory('PNSGuardian');

  const pnsGuardianContract = await upgrades.deployProxy(PNSGuardianContract, [adminAddress], { initializer: 'initialize' });
  await pnsGuardianContract.deployed();

  await pnsGuardianContract.setGuardianVerifier(adminAddress);
  console.log('PNS Guardian Contract Deployed to', pnsGuardianContract.address, 'PNS Guardian verifier set to', adminAddress);

  const pnsContract = await upgrades.deployProxy(PNSContractRegistry, [pnsGuardianContract.address], { initializer: 'initialize' });
  await pnsContract.deployed();

  return { pnsContract, adminAddress, pnsGuardianContract };
}

async function deployUpgradedContract(pnsContract) {
  const PNSV2MockContract = await ethers.getContractFactory('PNSV2Mock');

  const upgradedPNSContract = await upgrades.upgradeProxy(pnsContract, PNSV2MockContract);

  return { upgradedPNSContract };
}

module.exports = {
  deployContract,
  deployUpgradedContract,
};
