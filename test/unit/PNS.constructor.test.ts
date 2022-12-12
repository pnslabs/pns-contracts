import { ethers } from 'hardhat';

const { expect } = require('chai');
const { deployContract } = require('../../scripts/deploy');

describe('PNS Constructor', () => {
  let pnsRegistryContract;
  let adminAddress;

  before(async function () {
    const { pnsRegistryContract: _pnsRegistryContract, adminAddress: _adminAddress } = await deployContract();
    pnsRegistryContract = _pnsRegistryContract;
    adminAddress = _adminAddress;
  });

  //TODO rewwrite to OZ RBAC
  // it('should successfully add an admin address in constructor', async function () {
  //   const admin = await pnsRegistryContract.getAdmin(adminAddress);
  //   expect(admin[2]).to.equal(true);
  // });
});
