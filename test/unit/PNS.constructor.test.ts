import { ethers } from 'hardhat';

const { expect } = require('chai');

describe('PNS Constructor', () => {
  let adminAccount;
  let pnsContract;
  let adminAddress;

  before(async function () {
    [adminAccount] = await ethers.getSigners();
    // testVariables.signer1 = adminAccount;
    adminAddress = adminAccount.address;

    const PNSContract = await ethers.getContractFactory('PNS');

    pnsContract = await PNSContract.deploy();
  });

  it('should successfully add an admin address in constructor', async function () {
    const admin = await pnsContract.getAdmin(adminAddress);
    expect(admin[2]).to.equal(true);
  });
});
