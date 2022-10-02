# PNS

Phone Number Service (PNS) is a chain agnostic protocol designed to link a mobile phone number with EVM-compatible blockchain addresses.

<br />

# Implementations for registrars and resolvers for the PNS

The `PNS.sol` smart contract comes with these list of public setter functions:

```
setPhoneRecord
setOwner
linkPhoneToWallet
```

And these lists of public getter functions;

```
getRecord
getOwner
recordExists
```

These functions implement the IPNS.sol interface.

<br />

# IPNS Interface

The IPNS's interface is as follows:

## setPhoneRecord(bytes32 phoneHash, address owner, address resolver, string label) external

Sets a resolver record and links it to the phoneHash and owner.

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

# Developer guide

## How to setup

```
git clone https://github.com/pnsfoundation/PNS-Core.git

cd PNS-CORE

npm install
```

## Run local ganache

Add `PRIVATE_KEY_GANACHE` in your `.env` file and paste in your secret key. Then in your terminal, run:

```
ganache
```

## Run unit tests

```shell
npm run test
```
