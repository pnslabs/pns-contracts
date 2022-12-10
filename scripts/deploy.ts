import { ethers, upgrades } from 'hardhat';

async function deployContract() {
  let adminAccount;

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;

  const PNSRegistryContract = await ethers.getContractFactory('PNSRegistry');

  const PNSGuardianContract = await ethers.getContractFactory('PNSGuardian');

  const PNSResolverContract = await ethers.getContractFactory('PNSResolver');

  const pnsGuardianContract = await upgrades.deployProxy(PNSGuardianContract, [adminAddress], { initializer: 'initialize' });
  await pnsGuardianContract.deployed();

  await pnsGuardianContract.setGuardianVerifier(adminAddress);
  console.log('PNS Guardian Contract Deployed to', pnsGuardianContract.address, 'PNS Guardian verifier set to', adminAddress);

  const pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [pnsGuardianContract.address], { initializer: 'initialize' });
  await pnsRegistryContract.deployed();

  console.log('PNS Registry Contract Deployed to', pnsRegistryContract.address);

  const pnsResolverContract = await upgrades.deployProxy(PNSResolverContract, [pnsGuardianContract.address, pnsRegistryContract.address], { initializer: 'initialize' });
  await pnsResolverContract.deployed();

  console.log('PNS Resolver Contract Deployed to', pnsResolverContract.address);


  return { pnsRegistryContract, adminAddress, pnsGuardianContract, pnsResolverContract };
}

async function deployUpgradedContract(pnsRegistryContract) {
  const PNSV2MockContract = await ethers.getContractFactory('PNSV2Mock');

  const upgradedPNSRegistryContract = await upgrades.upgradeProxy(pnsRegistryContract, PNSV2MockContract);

  return { upgradedPNSRegistryContract };
}


module.exports = {
  deployContract,
  deployUpgradedContract,
};
