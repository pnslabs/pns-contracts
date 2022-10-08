import { ethers } from 'hardhat';

const { expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Constructor', () => {
  let adminAccount;

  before(async function () {
    [adminAccount] = await ethers.getSigners();
    testVariables.signer1 = adminAccount;
    testVariables.adminAddress = adminAccount.address;

    const PNSContract = await ethers.getContractFactory('PNS');

    testVariables.pnsContract = await PNSContract.deploy();
  });

  it('should successfully add an admin address in constructor', async function () {
    const admin = await testVariables.pnsContract.getAdmin(testVariables.adminAddress);
    console.log(admin);
    expect(admin[2]).to.equal(true);
  });
});
