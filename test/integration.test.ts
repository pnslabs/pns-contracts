import { ethers } from 'hardhat';
import hre from 'hardhat';
import { ethToWei, getEthBalance, toUnits, toWholeUnits, weiToEth } from './helpers/base';
import { domain, PNSTypes } from './helpers/eip712sign';

const { assert, expect } = require('chai');
const { keccak256 } = require('../utils/util');
const { deployContract } = require('../scripts/deploy');

describe.only('PNS Registry', () => {
  let pnsRegistryContract;
  let pnsGuardianContract;
  let pnsResolverContract;
  let adminAddress;
  let balanceBeforeTx;

  //using an enummeration  prone phoneHash
  const phoneNumber1 = keccak256('2347084562591');
  const phoneNumber2 = keccak256('08084442592');
  const oneYearInSeconds = 31536000;
  const twoYearsInSeconds = 63072000;
  const thirtyDaysInSeconds = 2592000;
  const label = 'ETH';
  const label2 = 'BTC';
  const status = true;
  const signer = ethers.provider.getSigner();
  const otp = '123456';
  let accounts: any[];
  let amountInETH;
  let amount = '10000000000000000000';
  let renewAmount = '5000000000000000000';
  let newSigner;

  let message = ethers.utils.solidityPack(['bytes32', 'uint256'], [phoneNumber1, otp]);
  const hashedMessage = ethers.utils.keccak256(message);
  let signature;

  before(async () => {
    accounts = await ethers.getSigners();
    const [joe, emma] = accounts.slice(1, 5);

    signature = await joe.signMessage(ethers.utils.arrayify(hashedMessage));

    const {
      pnsRegistryContract: _pnsRegistryContract,
      adminAddress: _adminAddress,
      pnsResolverContract: _pnsResolverContract,
      pnsGuardianContract: _pnsGuardianContract,
    } = await deployContract();

    pnsRegistryContract = _pnsRegistryContract;
    adminAddress = _adminAddress;
    pnsResolverContract = _pnsResolverContract;
    pnsGuardianContract = _pnsGuardianContract;
    adminAddress = _adminAddress;
  });

  it('Should register a phone number on PNS and set record', async () => {
    const [joe, emma] = accounts.slice(1, 5);
    const balance = await joe.provider.getBalance(joe.address);
    console.log(weiToEth(balance));

    console.log('this is address', joe.address);
    //joe encounters an error while verifying his phone number
    await expect(
      pnsGuardianContract.verifyPhoneHash(phoneNumber1, hashedMessage, status, emma.address, signature),
    ).to.be.revertedWith('signer does not match signature');
    //joe verifies his phone number successfully
    await expect(pnsGuardianContract.verifyPhoneHash(phoneNumber1, hashedMessage, status, joe.address, signature)).to
      .not.be.reverted;

    //joe's record authenticated successfully by guardian
    // let joeVerificationStatus = await pnsRegistryContract.getVerificationStatus(phoneNumber1);
    // await expect(joeVerificationStatus).to.be.equal(true);

    //joe's verification record is owned by joe
    // let verificationOwner = await pnsGuardianContract.getVerifiedOwner(phoneNumber1);
    // console.log('joeVerificationStatus', verificationOwner);
    // await expect(verificationOwner).to.be.equal(joe.address);

    //joe attempts to create a record with an unverified phone number
    // await expect(pnsRegistryContract.connect(joe).setPhoneRecord(phoneNumber2, joe.address)).to.be.revertedWith(
    //   'phone record is not verified',
    // );

    //joe retries with a verified phone number but forget to add balance
    // await expect(pnsRegistryContract.connect(joe).setPhoneRecord(phoneNumber1, joe.address)).to.be.revertedWith(
    //   'insufficient balance',
    // );

    //joe retries with a balance and creates a record successfully
    // await expect(
    //   pnsRegistryContract.connect(joe).setPhoneRecord(phoneNumber1, joe.address, { value: ethToWei('0.1') }),
    // ).to.emit(pnsRegistryContract, 'PhoneRecordCreated');

    // //Balance Checks
    // // const joeBalanceBeforeLink = await getEthBalance(joe.address);
    // const RegistryContractBalance = await getEthBalance(pnsRegistryContract.address);
  });
});
