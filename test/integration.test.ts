import { ethers } from 'hardhat';
import { formatsByName, formatsByCoinType } from '@ensdomains/address-encoder';
import { increaseTime, weiToEth } from './helpers/base';

const { assert, expect } = require('chai');
const { keccak256 } = require('../utils/util');
const { deployContract } = require('../scripts/deploy');

describe.only('PNS', () => {
  let pnsRegistryContract;
  let pnsGuardianContract;
  let pnsResolverContract;
  let adminAddress;

  //using an enummeration  prone phoneHash
  const phoneNumber1 = keccak256('2347084562591');
  const phoneNumber2 = keccak256('08084442592');
  const status = true;
  const otp = '123456';
  let accounts: any[];
  let amount = '10000000000000000000';
  let renewAmount = '5000000000000000000';
  const zeroAddress = ethers.constants.AddressZero;

  let message = ethers.utils.solidityPack(['bytes32', 'uint256'], [phoneNumber1, otp]);
  const hashedMessage = ethers.utils.keccak256(message);
  let signature;

  before(async () => {
    accounts = await ethers.getSigners();
    const [joe] = accounts.slice(1, 5);

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

  it('Should verify a phone number', async () => {
    const [joe, emma] = accounts.slice(1, 5);
    const joeInitialBalance = await joe.provider.getBalance(joe.address);
    const emmaInitialBalance = await emma.provider.getBalance(emma.address);
    console.log("Emma's initial balance:::", weiToEth(emmaInitialBalance));
    console.log("Joe's initial balance:::", weiToEth(joeInitialBalance));

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
  });

  it('Should create a phone record successfully', async () => {
    const [joe, emma] = accounts.slice(1, 5);

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
    await expect(pnsRegistryContract.connect(joe).setPhoneRecord(phoneNumber1, joe.address, { value: amount })).to.emit(
      pnsRegistryContract,
      'PhoneRecordCreated',
    );

    //joe verifies that the record exist and the ownership is set correctly
    let record = await pnsRegistryContract.getRecord(phoneNumber1);
    assert.equal(record.owner, joe.address);
  });

  it('Should transfer ownership to another address', async () => {
    const [joe, emma] = accounts.slice(1, 5);

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
    const record = await pnsRegistryContract.getRecord(phoneNumber1);
    assert.equal(record.owner, emma.address);
  });

  it('Should renew an expired record', async () => {
    const [joe, emma] = accounts.slice(1, 5);

    //emma encounters an error when trying to renew record before expiration
    await expect(pnsRegistryContract.connect(emma).renew(phoneNumber1)).to.be.revertedWith(
      'cannot proceed: record not expired',
    );

    //1 year later
    await increaseTime(365 * 86400);

    //emma encounters an error when trying to renew record with a wrong owner
    await expect(pnsRegistryContract.connect(joe).renew(phoneNumber1)).to.be.revertedWith('caller is not authorised');

    //emma encounters an error when trying to renew record with an insufficient balance
    await expect(pnsRegistryContract.connect(emma).renew(phoneNumber1)).to.be.revertedWith('insufficient balance');

    //emma renews phone record successfully
    await expect(pnsRegistryContract.connect(emma).renew(phoneNumber1, { value: renewAmount })).to.emit(
      pnsRegistryContract,
      'PhoneRecordRenewed',
    );

    //1yr + 60 days later
    await increaseTime((365 + 60) * 86400);

    //emma encounters an error when trying to transfer ownership when record has passed its grace period
    await expect(pnsRegistryContract.connect(emma).transfer(phoneNumber1, joe.address)).to.be.revertedWith(
      'cannot proceed: record expired',
    );

    //Balance Checks
    const joeBalance = await joe.provider.getBalance(joe.address);
    const emmaBalance = await emma.provider.getBalance(emma.address);
    console.log("Emma's balance now:::", weiToEth(emmaBalance));
    console.log("Joe's balance now:::", weiToEth(joeBalance));
  });

  it('Should add address to resolver', async () => {
    const [joe, emma] = accounts.slice(1, 5);
    //since joe has a record on the registry
    const owner = await pnsResolverContract.connect(joe).getOwner(phoneNumber1);
    assert.equal(owner, emma.address);

    //get eth record
    let resolveAddress = await pnsResolverContract['addr(bytes32)'](phoneNumber1);
    assert.equal(resolveAddress, joe.address);

    // change eth record to resolve emma
    await pnsResolverContract.connect(emma)['setAddr(bytes32,address)'](phoneNumber1, emma.address);
    resolveAddress = await pnsResolverContract['addr(bytes32)'](phoneNumber1);

    assert.equal(resolveAddress, emma.address);

    //joe decides to add BTC address to his resolve record
    const data = formatsByName['BTC'].decoder('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');
    console.log('this is btc data', data);
    await pnsResolverContract.connect(emma)['setAddr(bytes32,uint256,bytes)'](phoneNumber1, 0, data);
    const btcAddress = await pnsResolverContract['addr(bytes32,uint256)'](phoneNumber1, 0);

    // console.log('btc record', resolveAddress)
    // const addr = formatsByCoinType[0].encoder(btcAddress);
    // console.log('btcaddress', addr);
  });
});
