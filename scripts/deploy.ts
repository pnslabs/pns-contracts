import { ethers, upgrades } from 'hardhat';
import hre from 'hardhat';

import { chainlink_price_feeds } from './constants';

async function deployContract() {
  let adminAccount;
  let pnsRegistryContract;
  let registryCost = 10;
  let registryRenewCost = 5;

  console.log(hre.network.name, 'network name');

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;
  console.log(adminAddress, 'address');

  const PNSRegistryContract = await ethers.getContractFactory('PNSRegistry');

  const PNSResolverContract = await ethers.getContractFactory('PNSResolver');

  if (hre.network.name === 'ethereum_mainnet') {
    pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [chainlink_price_feeds.ETHEREUM_MAINNET], {
      initializer: 'initialize',
    });
  } else if (hre.network.name === 'bnb_mainnet') {
    pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [chainlink_price_feeds.BSC_MAINNET], {
      initializer: 'initialize',
    });
  } else if (hre.network.name === 'polygon_mainnet') {
    pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [chainlink_price_feeds.MATIC_MAINNET], {
      initializer: 'initialize',
    });
  } else if (hre.network.name === 'ethereum_goerli') {
    pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [chainlink_price_feeds.ETHEREUM_GOERLI], {
      initializer: 'initialize',
    });
  } else if (hre.network.name === 'bnb_testnet') {
    pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [chainlink_price_feeds.BSC_TESTNET], {
      initializer: 'initialize',
    });
  } else if (hre.network.name === 'polygon_mumbai') {
    pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [chainlink_price_feeds.MATIC_MUMBAI], {
      initializer: 'initialize',
    });
  } else {
    pnsRegistryContract = await upgrades.deployProxy(PNSRegistryContract, [chainlink_price_feeds.BSC_MAINNET], {
      initializer: 'initialize',
    });
  }
  await pnsRegistryContract.deployed();

  console.log('PNS Registry Contract Deployed to', pnsRegistryContract.address);
  await pnsRegistryContract.setRegistryCost(registryCost);
  await pnsRegistryContract.setRegistryRenewCost(registryRenewCost);
  console.log('Registry Cost set to', registryCost, 'Registry Renew Cost set to', registryRenewCost);

  await pnsRegistryContract.setGuardianVerifier(adminAddress);
  console.log('Guardian Verifier set to', adminAddress);

  const pnsResolverContract = await upgrades.deployProxy(PNSResolverContract, [pnsRegistryContract.address], {
    initializer: 'initialize',
  });
  await pnsResolverContract.deployed();

  console.log('PNS Resolver Contract Deployed to', pnsResolverContract.address);

  return { pnsRegistryContract, adminAddress, pnsResolverContract };
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

deployContract()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
