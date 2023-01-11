# PNS

Phone Number Service (PNS) is a chain agnostic protocol designed to link a mobile phone number with EVM-compatible blockchain addresses.

<br />

# Implementations for registrars and resolvers for the PNS

The `PNS.sol` smart contract comes with these list of public setter functions:

```
setPhoneRecord
setOwner
linkPhoneToWallet
renew
claimExpiredPhoneRecord
setPhoneRecordMapping
verifyPhone
```

And these lists of public getter functions;

```
getRecord
getResolver
recordExists
getExpiryTime
getGracePeriod
getAmountinETH
isRecordVerified
```

These functions implement the IPNS.sol interface.

<br />

# IPNS Interface

The IPNSRegistry's interface is as follows:

## setPhoneRecord(bytes32 phoneHash, address resolver, string label) external payable

Sets a resolver record and links it to the phoneHash.

<br />

## isRecordVerified(bytes32 phoneHash) external view returns (bool);

Checks if the specified phoneHash is verified.

<br />

## linkPhoneToWallet(bytes32 phoneHash, address resolver, string label) external

Sets the resolver address for the specified phoneHash.

<br />

## getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory);

Returns the PhoneRecord data linked to the specified phone number hash.

<br />

## getOwner(bytes32 phoneHash) external view returns (address)

Returns the address that owns the specified phoneHash.

<br />

## recordExists(bytes32 phoneHash) external view returns (bool)

Returns true or false on whether or not a record linked to the specified phoneHash exists.

<br />

## setOwner(bytes32 phoneHash, address owner) external

Transfers ownership of a phoneHash to a new address. May only be called by the current owner of the phoneHash.

<br />

## getResolver(bytes32 phoneHash) external view returns (ResolverRecord[] memory)

Returns an existing label for the specified phone number phoneHash.

<br />

## getExpiryTime() external view returns (uint256)

Gets the current expiry time.

<br />

## getGracePeriod() external view returns (uint256)

Gets the current grace period.

<br />

## renew(bytes32 phoneHash) external payable

Renew a phone record.

<br />

## claimExpiredPhoneRecord(bytes32 phoneHash, address resolver, string memory label) external

Claims an already existing but expired phone record, and sets a completely new resolver.

<br />

## getExpiryTime() external view returns (uint256)

Returns the default phone record expiry time

<br />

## getGracePeriod() external view returns (uint256)

Returns the default phone record grace period

<br />

## verifyPhone(bytes32 phoneHash, bytes32 hashedMessage, bool status, bytes memory signature) external

Function used to update the verification status of a phone number.

<br />

## getAmountinETH(uint256 usdAmount) external view returns (uint256)

Returns a USD amount converted to ETH

<br />

# Developer guide

## How to setup

```
git clone https://github.com/pnsfoundation/PNS-Core.git

cd PNS-CORE

yarn install
```

## Run local ganache

Add `PRIVATE_KEY_GANACHE` in your `.env` file and paste in your secret key. Then in your terminal, run:

```
ganache
```

## Run unit tests

```shell
yarn run test
```
