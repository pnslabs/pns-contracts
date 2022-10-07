import { network } from 'hardhat';

const { expect } = require('chai');
const { developmentChains, testVariables } = require('../../helper-hardhat-config');

!developmentChains.includes(network.name)
  ? describe.skip
  : describe('PNS Expiration', () => {
      const { phoneNumber } = testVariables;

      it('gets returns the expiration time of the phone record', async () => {
        const phoneRecord = await testVariables.pnsContract.getRecord(phoneNumber);

        expect(Number(phoneRecord[7])).to.be.greaterThan(0);
      });
    });
