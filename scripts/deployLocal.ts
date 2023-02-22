import { ethers, upgrades } from 'hardhat';
import hre from 'hardhat';

import { chainlink_price_feeds } from './constants';
import { ethToWei } from '../test/helpers/base';

async function deployContract() {
  let adminAccount;
  let pnsRegistryContract;
  let registryCost = ethToWei('10'); // 10 usd
  let registryRenewCost = ethToWei('5'); // 5 usd
  let ethPrice = '163759050000';

  const treasuryAddress = '0x';

  console.log(hre.network.name, 'network name');

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;
  console.log(adminAddress, 'address');

  const PNSRegistryContract = await ethers.getContractFactory('PNSRegistry');

  const PNSResolverContract = await ethers.getContractFactory('PNSResolver');

  const PNSGuardianContract = await ethers.getContractFactory('PNSGuardian');

  const DummyPriceOracleContract = await ethers.getContractFactory('DummyPriceOracle');

  const PriceConverter = await ethers.getContractFactory('PriceConverter');

  const dummyPriceOrcleContract = await DummyPriceOracleContract.deploy(ethPrice);

  const priceConverter = await PriceConverter.deploy(dummyPriceOrcleContract.address);
  await priceConverter.deployed();

  const pnsGuardianContract = await upgrades.deployProxy(PNSGuardianContract, [adminAddress], {
    initializer: 'initialize',
  });
  await pnsGuardianContract.deployed();

  console.log('PNS Guardian Contract Deployed to', pnsGuardianContract.address);

  pnsRegistryContract = await upgrades.deployProxy(
    PNSRegistryContract,
    [pnsGuardianContract.address, priceConverter.address, adminAddress, treasuryAddress],
    {
      initializer: 'initialize',
    },
  );

  await pnsRegistryContract.deployed();

  console.log('PNS Registry Contract Deployed to', pnsRegistryContract.address);
  await pnsRegistryContract.setRegistryCost(registryCost);
  const pnsRegistrycost = await pnsRegistryContract.registryCostInUSD();
  await pnsRegistryContract.setRegistryRenewCost(registryRenewCost);
  const pnsRegistryRenewCost = await pnsRegistryContract.registryRenewCostInUSD();
  console.log(
    `Registry Cost set to ${pnsRegistrycost / 1e18} USD, \n Registry Renew Cost set to, ${
      pnsRegistryRenewCost / 1e18
    } USD`,
  );

  await pnsGuardianContract.setPNSRegistry(pnsRegistryContract.address);
  console.log('Registry contract set to', pnsRegistryContract.address);

  const pnsResolverContract = await upgrades.deployProxy(PNSResolverContract, [pnsRegistryContract.address], {
    initializer: 'initialize',
  });
  await pnsResolverContract.deployed();

  console.log('PNS Resolver Contract Deployed to', pnsResolverContract.address);

  return { pnsRegistryContract, pnsGuardianContract, adminAddress, pnsResolverContract };
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
