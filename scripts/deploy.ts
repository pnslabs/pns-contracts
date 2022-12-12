import { ethers, upgrades } from 'hardhat';
import hre from 'hardhat';

// import { chainlink_price_feeds } from './constants';

async function deployContract() {
  let adminAccount;
  let priceOracleContract;
  let registryCost = 10;
  let registryRenewCost = 5;

  console.log(hre.network.name, 'network name');

  [adminAccount] = await ethers.getSigners();
  const adminAddress = adminAccount.address;
  console.log(adminAddress, 'address');

  const PNSRegistryContract = await ethers.getContractFactory('PNSRegistry');

  const PNSGuardianContract = await ethers.getContractFactory('PNSGuardian');

  const PNSResolverContract = await ethers.getContractFactory('PNSResolver');

  // const pnsGuardianContract = await upgrades.deployProxy(PNSGuardianContract, [adminAddress], { initializer: 'initialize' });
  // await pnsGuardianContract.deployed();

  // await pnsGuardianContract.setGuardianVerifier(adminAddress);
  // console.log('PNS Guardian Contract Deployed to', pnsGuardianContract.address, 'PNS Guardian verifier set to', adminAddress);

  // if (hre.network.name === 'ethereum_mainnet') {
  //   priceOracleContract = await upgrades.deployProxy(PriceOracleContract, [chainlink_price_feeds.ETHEREUM_MAINNET], {
  //     initializer: 'initialize',
  //   });
  // } else if (hre.network.name === 'bnb_mainnet') {
  //   priceOracleContract = await upgrades.deployProxy(PriceOracleContract, [chainlink_price_feeds.BSC_MAINNET], {
  //     initializer: 'initialize',
  //   });
  // } else if (hre.network.name === 'polygon_mainnet') {
  //   priceOracleContract = await upgrades.deployProxy(PriceOracleContract, [chainlink_price_feeds.MATIC_MAINNET], {
  //     initializer: 'initialize',
  //   });
  // } else if (hre.network.name === 'ethereum_goerli') {
  //   priceOracleContract = await upgrades.deployProxy(PriceOracleContract, [chainlink_price_feeds.ETHEREUM_GOERLI], {
  //     initializer: 'initialize',
  //   });
  // } else if (hre.network.name === 'bnb_testnet') {
  //   priceOracleContract = await upgrades.deployProxy(PriceOracleContract, [chainlink_price_feeds.BSC_TESTNET], {
  //     initializer: 'initialize',
  //   });
  // } else if (hre.network.name === 'polygon_mumbai') {
  //   priceOracleContract = await upgrades.deployProxy(PriceOracleContract, [chainlink_price_feeds.MATIC_MUMBAI], {
  //     initializer: 'initialize',
  //   });
  // } else {
  //   priceOracleContract = await upgrades.deployProxy(PriceOracleContract, [chainlink_price_feeds.BSC_MAINNET], {
  //     initializer: 'initialize',
  //   });
  // }

  await priceOracleContract.deployed();

  console.log('Price Oracle Contract Deployed to', priceOracleContract.address);

  const pnsRegistryContract = await upgrades.deployProxy(
    PNSRegistryContract,
    [adminAddress, priceOracleContract.address],
    { initializer: 'initialize' },
  );
  await pnsRegistryContract.deployed();

  console.log('PNS Registry Contract Deployed to', pnsRegistryContract.address);
  await pnsRegistryContract.updateRegistryCost(registryCost);
  await pnsRegistryContract.updateRegistryRenewCost(registryRenewCost);

  console.log('Registry Cost set to', registryCost, 'Registry Renew Cost set to', registryRenewCost);

  const pnsResolverContract = await upgrades.deployProxy(
    PNSResolverContract,
    [adminAddress, pnsRegistryContract.address],
    { initializer: 'initialize' },
  );
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
