import { ethers, upgrades } from 'hardhat';
import hre from 'hardhat';

import { chainlink_price_feeds } from './constants';
import { ethToWei } from '../test/helpers/base';

async function deployContract() {
  let adminAccount;
  let pnsRegistryContract;
  let registryCost = ethToWei('9.99'); // 10 usd
  let registryRenewCost = ethToWei('4.99'); // 5 usd
  let ethPrice = '1779400000000';
  const ethGoerliTreasuryAddress = process.env.GNOSIS_GOERLI_TREASURY_ADDRESS;
  const bscTestnetTreasuryAddress = '0x';
  const maticMumbaiTreasuryAddress = '0x';
  const bscMainnetTreasuryAddress = '0x';
  const maticMainnetTreasuryAddress = '0x';
  const ethMainnetTreasuryAddress = '0x';

  console.log(hre.network.name, 'network name');

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;
  console.log(adminAddress, 'address');
  console.log('------------------------------------------------');

  const PNSRegistryContract = await ethers.getContractFactory('PNSRegistry');

  const PNSResolverContract = await ethers.getContractFactory('PNSResolver');

  const PNSGuardianContract = await ethers.getContractFactory('PNSGuardian');

  const DummyPriceOracleContract = await ethers.getContractFactory('DummyPriceOracle');

  const dummyPriceOrcleContract = await DummyPriceOracleContract.deploy(ethPrice);
  await dummyPriceOrcleContract.deployed();
  const PriceConverter = await ethers.getContractFactory('PriceConverter');

  const priceConverter = await PriceConverter.deploy(dummyPriceOrcleContract.address);
  await priceConverter.deployed();

  const pnsGuardianContract = await upgrades.deployProxy(PNSGuardianContract, [adminAddress], {
    initializer: 'initialize',
  });
  await pnsGuardianContract.deployed();

  console.log('PNS Guardian Contract Deployed to', pnsGuardianContract.address);
  console.log('------------------------------------------------');

  if (hre.network.name === 'ethereum_mainnet') {
    pnsRegistryContract = await upgrades.deployProxy(
      PNSRegistryContract,
      [pnsGuardianContract.address, chainlink_price_feeds.ETHEREUM_MAINNET, adminAddress, ethMainnetTreasuryAddress],
      {
        initializer: 'initialize',
      },
    );
  } else if (hre.network.name === 'bnb_mainnet') {
    pnsRegistryContract = await upgrades.deployProxy(
      PNSRegistryContract,
      [pnsGuardianContract.address, chainlink_price_feeds.BSC_MAINNET, adminAddress, bscMainnetTreasuryAddress],
      {
        initializer: 'initialize',
      },
    );
  } else if (hre.network.name === 'polygon_mainnet') {
    pnsRegistryContract = await upgrades.deployProxy(
      PNSRegistryContract,
      [pnsGuardianContract.address, chainlink_price_feeds.MATIC_MAINNET, adminAddress, maticMainnetTreasuryAddress],
      {
        initializer: 'initialize',
      },
    );
  } else if (hre.network.name === 'ethereum_goerli') {
    pnsRegistryContract = await upgrades.deployProxy(
      PNSRegistryContract,
      [pnsGuardianContract.address, chainlink_price_feeds.ETHEREUM_GOERLI, adminAddress, ethGoerliTreasuryAddress],
      {
        initializer: 'initialize',
      },
    );
  } else if (hre.network.name === 'bnb_testnet') {
    pnsRegistryContract = await upgrades.deployProxy(
      PNSRegistryContract,
      [pnsGuardianContract.address, chainlink_price_feeds.BSC_TESTNET, bscTestnetTreasuryAddress],
      {
        initializer: 'initialize',
      },
    );
  } else if (hre.network.name === 'polygon_mumbai') {
    pnsRegistryContract = await upgrades.deployProxy(
      PNSRegistryContract,
      [pnsGuardianContract.address, chainlink_price_feeds.MATIC_MUMBAI, maticMumbaiTreasuryAddress],
      {
        initializer: 'initialize',
      },
    );
  } else {
    const treasuryAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
    pnsRegistryContract = await upgrades.deployProxy(
      PNSRegistryContract,
      [pnsGuardianContract.address, priceConverter.address, treasuryAddress],
      {
        initializer: 'initialize',
      },
    );
  }
  await pnsRegistryContract.deployed();

  console.log('PNS Registry Contract Deployed to', pnsRegistryContract.address);
  console.log('------------------------------------------------');
  await pnsRegistryContract.setRegistryCost(registryCost);
  const pnsRegistrycost = await pnsRegistryContract.registryCostInUSD();
  await pnsRegistryContract.setRegistryRenewCost(registryRenewCost);
  const pnsRegistryRenewCost = await pnsRegistryContract.registryRenewCostInUSD();
  await pnsGuardianContract.setPNSRegistry(pnsRegistryContract.address);
  const guardianRegistry = await pnsGuardianContract.registryAddress();
  console.log('Registry contract in guardian after deployment', guardianRegistry);
  console.log('------------------------------------------------');
  console.log(
    `Registry Cost set to ${pnsRegistrycost / 1e18} USD, \n Registry Renew Cost set to, ${
      pnsRegistryRenewCost / 1e18
    } USD`,
  );
  console.log('------------------------------------------------');

  await pnsGuardianContract.setPNSRegistry(pnsRegistryContract.address);

  console.log('Registry contract in guardian set to', pnsRegistryContract.address);
  console.log('------------------------------------------------');

  const pnsResolverContract = await upgrades.deployProxy(PNSResolverContract, [pnsRegistryContract.address], {
    initializer: 'initialize',
  });
  await pnsResolverContract.deployed();
  await pnsRegistryContract.setResolver(pnsResolverContract.address);

  console.log('PNS Resolver Contract Deployed to', pnsResolverContract.address);
  console.log('------------------------------------------------');

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
