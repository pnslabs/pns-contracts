import { network } from 'hardhat';

const { assert, expect } = require('chai');
const { developmentChains, testVariables } = require('../../helper-hardhat-config');

!developmentChains.includes(network.name)
  ? describe.skip
  : describe('PNS Label linking', () => {
      const { phoneNumber, label1, label2 } = testVariables;

      //misleading test
      it('verifies that new recorded created exist', async () => {
        await expect(testVariables.pnsContract.linkPhoneToWallet(phoneNumber, testVariables.adminAddress, label2)).to
          .not.be.reverted;
        testVariables.resolverCreatedLength++;
      });

      it('verifies that all currently created resolvers are available', async () => {
        const resolvers = await testVariables.pnsContract.getResolverDetails(phoneNumber);
        const wallets = resolvers.length;

        assert.equal(wallets, testVariables.resolverCreatedLength);
      });

      it('verifies that labels are correct', async () => {
        const resolvers = await testVariables.pnsContract.getResolverDetails(phoneNumber);
        const firstLabel = resolvers[0][2];
        const secondLabel = resolvers[1][2];

        assert.equal(firstLabel, label1);
        assert.equal(secondLabel, label2);
      });
    });
