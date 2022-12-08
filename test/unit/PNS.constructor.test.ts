import { ethers } from 'hardhat';

const { expect } = require('chai');
const { deployContract } = require('../../scripts/deploy');

describe('PNS Constructor', () => {
  let pnsContract;
  let adminAddress;

  before(async function () {
    const { pnsContract: _pnsContract, adminAddress: _adminAddress } = await deployContract();
    pnsContract = _pnsContract;
    adminAddress = _adminAddress;
  });


  //TODO rewwrite to OZ RBAC
  // it('should successfully add an admin address in constructor', async function () {
  //   const admin = await pnsContract.getAdmin(adminAddress);
  //   expect(admin[2]).to.equal(true);
  // });
});
