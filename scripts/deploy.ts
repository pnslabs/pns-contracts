import { ethers, upgrades } from 'hardhat';

async function main() {
  let pns;

  const PNS = await ethers.getContractFactory('PNS');
  console.log('Deploying PNS...');

  pns = await upgrades.deployProxy(PNS, [], { initializer: 'initialize' });
  await pns.deployed();
  console.log('PNS Contract Deployed to', pns.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
