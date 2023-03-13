import { ethers } from 'hardhat';
import hre from 'hardhat';
import { ethToWei, getEthBalance, increaseTime, toUnits, toWholeUnits, weiToEth } from './helpers/base';
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
  const sixtyDaysInSeconds = 5184000;
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
  const zeroAddress = ethers.constants.AddressZero;

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
    const joeInitialBalance = await joe.provider.getBalance(joe.address);
    console.log("Joe's initial balance:::", joeInitialBalance);

    //joe encounters an error while verifying his phone number with a wrong owner
    await expect(
      pnsGuardianContract.verifyPhoneHash(phoneNumber1, hashedMessage, status, emma.address, signature),
    ).to.be.revertedWith('signer does not match signature');

    //joe encounters an error while verifying his phone number with a wrong verifier
    await expect(
      pnsGuardianContract.connect(joe).verifyPhoneHash(phoneNumber1, hashedMessage, status, emma.address, signature),
    ).to.be.revertedWith('Only Guardian Verifier');

    //joe verifies his phone number successfully
    await expect(
      pnsGuardianContract.verifyPhoneHash(phoneNumber1, hashedMessage, status, joe.address, signature),
    ).to.emit(pnsGuardianContract, 'PhoneVerified');

    //joe verifies that his ownership is verified correctly
    const owner = await pnsGuardianContract.getVerifiedOwner(phoneNumber1);
    assert.equal(owner, joe.address);

    //joe encounters an error when attempting to create a record with an unverified phone number
    await expect(pnsRegistryContract.connect(joe).setPhoneRecord(phoneNumber2, joe.address)).to.be.revertedWith(
      'phone record is not verified',
    );

    //joe encounters an error when attempting to create a record when connected to the wrong owner
    await expect(pnsRegistryContract.connect(emma).setPhoneRecord(phoneNumber1, joe.address)).to.be.revertedWith(
      'caller is not verified owner',
    );

    //joe encounters an error when attempting to create a record with an insufficient balance
    await expect(pnsRegistryContract.connect(joe).setPhoneRecord(phoneNumber1, joe.address)).to.be.revertedWith(
      'insufficient balance',
    );

    //joe creates a record successfully
    await expect(
      pnsRegistryContract.connect(joe).setPhoneRecord(phoneNumber1, joe.address, { value: ethToWei('1') }),
    ).to.emit(pnsRegistryContract, 'PhoneRecordCreated');

    //joe verifies that the record exist and the ownership is set correctly
    let record = await pnsRegistryContract.getRecord(phoneNumber1);
    assert.equal(record.owner, joe.address);

    //joe encounters an error when trying to transfer ownership using the wrong owner
    await expect(pnsRegistryContract.connect(emma).transfer(phoneNumber1, emma.address)).to.be.revertedWith(
      'caller is not authorised',
    );

    //joe encounters an error when trying to transfer ownership using the zero address
    await expect(pnsRegistryContract.connect(joe).transfer(phoneNumber1, zeroAddress)).to.be.revertedWith(
      'cannot set owner to the zero address',
    );

    //joe encounters an error when trying to transfer ownership using the contract address
    await expect(
      pnsRegistryContract.connect(joe).transfer(phoneNumber1, pnsRegistryContract.address),
    ).to.be.revertedWith('cannot set owner to the registry address');

    //joe transfers phone record ownership to emma successfully
    await expect(pnsRegistryContract.connect(joe).transfer(phoneNumber1, emma.address)).to.emit(
      pnsRegistryContract,
      'Transfer',
    );

    //emma verifies that the ownership is set correctly
    record = await pnsRegistryContract.getRecord(phoneNumber1);
    assert.equal(record.owner, emma.address);

    //emma encounters an error when trying to renew record before expiration
    await expect(pnsRegistryContract.connect(emma).renew(phoneNumber1)).to.be.revertedWith(
      'cannot proceed: record not expired',
    );

    //increase evm time
    await increaseTime(oneYearInSeconds);

    //emma encounters an error when trying to renew record with a wrong owner
    await expect(pnsRegistryContract.connect(joe).renew(phoneNumber1)).to.be.revertedWith('caller is not authorised');

    //emma encounters an error when trying to renew record with an insufficient balance
    await expect(pnsRegistryContract.connect(emma).renew(phoneNumber1)).to.be.revertedWith('insufficient balance');

    //emma renews phone record successfully
    await expect(pnsRegistryContract.connect(emma).renew(phoneNumber1, { value: ethToWei('0.5') })).to.emit(
      pnsRegistryContract,
      'PhoneRecordRenewed',
    );

    //increase evm time
    await increaseTime(oneYearInSeconds + sixtyDaysInSeconds);

    //emma encounters an error when trying to transfer ownership when record has passed its grace period
    await expect(pnsRegistryContract.connect(emma).transfer(phoneNumber1, joe.address)).to.be.revertedWith(
      'cannot proceed: record expired',
    );

    //Balance Checks
    const joeBalance = await joe.provider.getBalance(joe.address);

    console.log("Joe's balance now:::", joeBalance);
  });
});
