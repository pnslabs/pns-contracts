import { network } from 'hardhat';

const { assert, expect } = require('chai');
const { developmentChains, testVariables } = require('../../helper-hardhat-config');

!developmentChains.includes(network.name)
  ? describe.skip
  : describe('PNS Label linking', () => {
      const { phoneNumber1, label1, label2, phoneNumber3 } = testVariables;

      // will come back to this

      // it('should throw an error if an unauthorized user tries to add a new resolver', async () => {
      //   await expect(
      //     testVariables.pnsContract.linkPhoneToWallet(phoneNumber1, testVariables.adminAddress, label2, {
      //       from: address1,
      //     }),
      //   ).to.be.revertedWith('caller is not authorised');
      // });

      it('should link a new resolver to a phone record', async () => {
        await expect(testVariables.pnsContract.linkPhoneToWallet(phoneNumber1, testVariables.adminAddress, label2)).to
          .not.be.reverted;
        testVariables.resolverCreatedLength++;
      });

      it('verifies that all previously created resolvers exists', async () => {
        const resolvers = await testVariables.pnsContract.getResolverDetails(phoneNumber1);
        const wallets = resolvers.length;

        assert.equal(wallets, testVariables.resolverCreatedLength);
      });

      it('should throw an error if phone record of a resolver does not exist', async () => {
        await expect(testVariables.pnsContract.getResolverDetails(phoneNumber3)).to.be.revertedWith(
          'phone record not found',
        );
      });

      it('should get the details of a specific resolver', async () => {
        const resolvers = await testVariables.pnsContract.getResolverDetails(phoneNumber1);
        const firstLabel = resolvers[0][2];
        const secondLabel = resolvers[1][2];

        assert.equal(firstLabel, label1);
        assert.equal(secondLabel, label2);
      });
    });
