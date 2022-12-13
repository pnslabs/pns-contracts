// import { network, ethers } from 'hardhat';

// const { expect, assert } = require('chai');
// const { keccak256 } = require('../../utils/util');
// const { deployContract } = require('../../scripts/deploy');

// describe('PNS Expire', () => {
//   let pnsRegistryContract;
//   let adminAddress;
//   let pnsGuardianContract;
//   let pnsResolverContract;

//   const phoneNumber = keccak256('07084462591');
//   const oneYearInSeconds = 31536000;
//   const twoYearsInSeconds = 63072000;
//   const thirtyDaysInSeconds = 2592000;
//   const label1 = 'ETH';
//   const label2 = 'BTC';
//   const address = '0xcD058D84F922450591AD59303AA2B4A864da19e6';
//   const status = true;
//   const signer = ethers.provider.getSigner();
//   const otp = '123456';

//   let message = ethers.utils.solidityPack(['bytes32', 'uint256'], [phoneNumber, otp]);
//   const hashedMessage = ethers.utils.keccak256(message);
//   let signature;

//   before(async function () {
//     signature = await signer.signMessage(ethers.utils.arrayify(hashedMessage));
//     const {
//       pnsRegistryContract: _pnsRegistryContract,
//       adminAddress: _adminAddress,
//       pnsGuardianContract: _pnsGuardianContract,
//       pnsResolverContract: _pnsResolverContract,
//     } = await deployContract();
//     pnsGuardianContract = _pnsGuardianContract;
//     adminAddress = _adminAddress;
//     pnsRegistryContract = _pnsRegistryContract;
//     pnsResolverContract = _pnsResolverContract;
//   });

//   it('should verify the phone number', async () => {
//     await expect(pnsGuardianContract.setVerificationStatus(phoneNumber, hashedMessage, status, signature)).to.emit(
//       pnsGuardianContract,
//       'PhoneVerified',
//     );
//   });

//   it('should create a new record and emit an event', async function () {
//     await expect(pnsRegistryContract.setPhoneRecord(phoneNumber, adminAddress, label1)).to.emit(
//       pnsRegistryContract,
//       'PhoneRecordCreated',
//     );
//   });

//   it('admin can set a new expiry time and it emits the expected event', async () => {
//     await expect(pnsRegistryContract.setExpiryTime(twoYearsInSeconds)).to.emit(
//       pnsRegistryContract,
//       'ExpiryTimeUpdated',
//     );
//   });

//   it('admin can set a new grace period and it emits the expected event', async () => {
//     await expect(pnsRegistryContract.setGracePeriod(thirtyDaysInSeconds)).to.emit(
//       pnsRegistryContract,
//       'GracePeriodUpdated',
//     );
//   });

//   it('gets returns the expiration time of the phone record', async () => {
//     const phoneRecord = await pnsResolverContract.getRecord(phoneNumber);
//     console.log(phoneRecord, 'phone record from the resolver');
//     expect(Number(phoneRecord[7])).to.be.greaterThan(0);
//   });

//   it('reverts with an error when attempting to renew a phone record that is not in grace period', async () => {
//     await expect(pnsRegistryContract.renew(phoneNumber)).to.be.revertedWith(
//       'only a phone record currently in grace period can be renewed',
//     );
//   });

//   it('increases the evm time to be in grace period, while expiration status remains false', async () => {
//     await network.provider.send('evm_increaseTime', [oneYearInSeconds]);
//     await network.provider.send('evm_mine', []);
//     const getRecord = await pnsResolverContract.getRecord(phoneNumber);
//     expect(getRecord[5]).to.equal(true);
//     expect(getRecord[6]).to.equal(false);
//   });

//   it('successfully renews an unexpired phone record that is in grace period, and emits an event', async () => {
//     await expect(pnsRegistryContract.renew(phoneNumber)).to.emit(pnsRegistryContract, 'PhoneRecordRenewed');
//   });

//   it('reverts with an error when attempting to claim an unexpired phone record', async () => {
//     await expect(
//       pnsRegistryContract.claimExpiredPhoneRecord(phoneNumber, adminAddress, adminAddress, label1),
//     ).to.be.revertedWith('only an expired phone record can be claimed');
//   });

//   it('increases the evm time until it exceeds the phone record expiration time', async () => {
//     await network.provider.send('evm_increaseTime', [twoYearsInSeconds + thirtyDaysInSeconds + 1]);
//     await network.provider.send('evm_mine', []);
//     const getRecord = await pnsResolverContract.getRecord(phoneNumber);
//     expect(getRecord[5]).to.equal(true);
//     expect(getRecord[6]).to.equal(true);
//   });

//   it('successfully claims an expired phone record, and emits an event', async () => {
//     await expect(pnsRegistryContract.claimExpiredPhoneRecord(phoneNumber, address, address, label2)).to.emit(
//       pnsRegistryContract,
//       'PhoneRecordCreated',
//     );
//   });

//   it('successfully deletes the previous record, and sets a new one when record is claimed.', async () => {
//     const resolvers = await pnsResolverContract.getResolverDetails(phoneNumber);
//     const wallets = resolvers.length;
//     const label = resolvers[0][2];

//     assert.equal(wallets, 1);
//     assert.equal(label, label2);
//   });
// });
