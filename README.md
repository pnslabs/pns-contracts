# PNS

Phone Number Service (PNS) is a chain agnostic protocol designed to link a mobile phone number with EVM-compatible blockchain addresses.

<br />

# Implementations for registrars and resolvers for the PNS

The `PNS.sol` smart contract comes with these list of public setter functions:

```
setPhoneRecord
setOwner
linkPhoneToWallet
reAuthenticate
claimExpiredPhoneRecord
```

And these lists of public getter functions;

```
getRecord
getOwner
recordExists
getExpiryTime
getGracePeriod
```

These functions implement the IPNS.sol interface.

<br />

# IPNS Interface

The IPNS's interface is as follows:

## setPhoneRecord(bytes32 phoneHash, address owner, address resolver, string label) external

Sets a resolver record and links it to the phoneHash and owner.

<br />

## linkPhoneToWallet(bytes32 phoneHash, address resolver, string label) external

Sets the resolver address for the specified phoneHash.

<br />

## getRecord(bytes32 phoneHash) external view returns (address owner, ResolverRecord[] memory, bytes32, uint256 createdAt, bool exists );

Returns the resolver details of the specified phoneHash.

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

## getResolverDetails(bytes32 phoneHash) external view returns (ResolverRecord[] memory)

Returns an existing label for the specified phone number phoneHash.

<br />

## getExpiryTime() external view returns (uint256)

Gets the current expiry time.

<br />

## getGracePeriod() external view returns (uint256)

Gets the current grace period.

<br />

## reAuthenticate(bytes32 phoneHash) external

Re authenticates a phone record.

<br />

## claimExpiredPhoneRecord(bytes32 phoneHash, address owner) external

Claims an already existing but expired phone record.

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
