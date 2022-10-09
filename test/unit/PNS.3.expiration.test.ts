import { network } from 'hardhat';

const { expect } = require('chai');
const { testVariables } = require('../../helper-hardhat-config');

describe('PNS Expiration', () => {
  const { phoneNumber1 } = testVariables;

  it('gets returns the expiration time of the phone record', async () => {
    const phoneRecord = await testVariables.pnsContract.getRecord(phoneNumber1);

    expect(Number(phoneRecord[7])).to.be.greaterThan(0);
  });
});
