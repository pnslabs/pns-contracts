import { network } from 'hardhat';

const { assert, expect } = require('chai');
const { developmentChains, testVariables } = require('../../helper-hardhat-config');

!developmentChains.includes(network.name)
  ? describe.skip
  : describe('PNS Owner', () => {
      const { phoneNumber, normalAccount } = testVariables;

      it('gets the correct owner of the record', async () => {
        const recordOwner = await testVariables.pnsContract.getOwner(phoneNumber);

        assert.equal(recordOwner, testVariables.adminAddress);
      });

      it('changes record owner', async () => {
        await expect(
          testVariables.pnsContract.setOwner(phoneNumber, normalAccount, { from: testVariables.adminAddress }),
        ).to.not.be.reverted;
      });

      it('gets new record owner', async () => {
        const recordOwner = await testVariables.pnsContract.getOwner(phoneNumber);
        assert.equal(recordOwner, normalAccount);
      });
    });
