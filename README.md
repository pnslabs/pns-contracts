# PNS Protocol

Phone Number Service (PNS) is a protocol that allows you to associate your phone number to wallet addresses.

This repository contains the Solidity smart contracts for the PNS Protocol

## Table of Contents

## Table of Contents

- [PNS Protocol](#pns-protocol)
  - [Table of Contents](#table-of-contents)
  - [Architecture](#architecture)
  - [Contracts](#contracts)
  - [Documentation](#documentation)
  - [Usage](#usage)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Deploying](#deploying)
     - [Testing](#testing)
  - [License](#license)
# Contract Design

## Architecture

The PNS Protocol comprises of several components: 

- **`PNS Registry`**  

  The PNS Registry contract.

  The registry contract is the core function that lies at the heart of phone number resolution. 

  The `setPhoneRecord` function allows for initial creation of phone record.

- **`PNS Resolver`** 
The PNS resolvers are responsible for setting resolvers and translating phone numbers into addresses. 

The resolver functions allows for:
  1. setting the resolvers for the phone number
  2. returning the reolver details of a phone number.

- **`PNS Guardian`**
The PNS Guardian contract is the entry point for record creation and it's responsible for verification of phone numbers.

The `setVerificationStatus` function updates user authentication state after verifying an otp onchain through it's signature using ECDSA verification scheme. The Guardian contract is the only authotized contract to access the guardian.

## Contracts

The smart contracts are stored under the `contracts` directory.

Files marked with an asterisk (\*) are specific to [sound.xyz](https://sound.xyz),  
but you can refer to them if you are building contracts to interact with them on-chain,   
or building your own customized versions.

```ml
contracts/
├── Interface
│   ├── IPNSGuardian.sol * ─ "PNS Guardian Interface"
│   ├── IPNSRegistry.sol * ─ "PNS Registry implementation interface"
│   ├── IPNSResolver.sol * ─ "NS Resolver implementation interface"
├── PNSGuardian.sol * ─ "PNS Guardian implementation for phone number verification"
├── PNSRegistry.sol * ─ "PNS Registry logic for phone number records"
├── PNSResolver.sol * ─ "Responsible for resolving phone numbers to addresses"
├── PriceOracle.sol * ─ "Handles price calculations and interacts with chainlink oracle for price conversions"
```


## Documentation

A comprehensive documentation is currently in the works.  

## Usage

### Prerequisites

-   [git](https://git-scm.com/downloads)
-   [nodeJS](https://nodejs.org/en/download/)
-   [brew](https://brew.sh/)
-   [foundry](https://getfoundry.sh) - You can run `sh ./setup.sh` to install Foundry and its dependencies.
-   [Hardhat](https://hardhat.org)

### Setup

-   Clone the repository

    ```bash
   git clone https://github.com/pnslabs/pns-contracts.git
    cd pns-contracts
    ```

-   Install packages

    ```
    yarn
    ```
 -   Build contracts

    ```
    yarn build
    ```


### Deploying

Create a .env in the root with:

```
PRIVATE_KEY=PRIVATE_KEY
ALCHEMY_API_KEY=
```

Then run:
```
yarn run deploy:ethereum_goerli
```

## Run unit tests

```shell
yarn run test
```


## License

[MIT](LICENSE) Copyright 2022 Sound PNS Labs