import { ethers, network } from 'hardhat';

const { assert, expect } = require('chai');
const { developmentChains, testVariables } = require('../../helper-hardhat-config');

!developmentChains.includes(network.name)
  ? describe.skip
  : describe('PNS Record', () => {
      let adminAccount;
      const { phoneNumber, label1 } = testVariables;

      before(async function () {
        [adminAccount] = await ethers.getSigners();
        testVariables.adminAddress = adminAccount.address;

        const PNSContract = await ethers.getContractFactory('PNS');

        testVariables.pnsContract = await PNSContract.deploy();
      });

      it('should create a new record', async function () {
        await expect(
          testVariables.pnsContract.setPhoneRecord(
            phoneNumber,
            testVariables.adminAddress,
            testVariables.adminAddress,
            label1,
          ),
        ).to.not.be.reverted;

        testVariables.resolverCreatedLength++;
      });

      it('verifies that new recorded created exist', async () => {
        const phoneRecordExist = await testVariables.pnsContract.recordExists(phoneNumber);

        assert.equal(phoneRecordExist, true);
      });

      it('ties the correct owner to record', async () => {
        const phoneRecord = await testVariables.pnsContract.getRecord(phoneNumber);
        assert.equal(phoneRecord.owner, testVariables.adminAddress);
      });
    });
