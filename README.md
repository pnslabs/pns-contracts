# **PNS Protocol**
## DISCLAMER: This repo is currently under active development and is not ready to be used in production

Phone Number Service (PNS) is a chain agnostic protocol designed to link a mobile phone number with EVM-compatible blockchain addresses.

This repository contains the Solidity smart contracts for the PNS Protocol

## **Table of Contents**

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
- [Contributing](#contributiong)
- [Code Of Conduct](#conduct)

## **Architecture**

The PNS Protocol comprises of several components: 

### PNS Registry
The PNS Registry contract holds the core functions that lie at the heart of phone number resolution.

### PNS Resolver
The PNS resolver is responsible for setting resolvers and translating phone numbers into addresses. 

The resolver functions allows for:
- setting the resolvers for the phone number
- returning the reolver details of a phone number.

The PNS Resolver mapping is adaptive to [ENS EIP 2304](https://eips.ethereum.org/EIPS/eip-2304) method with a bit of twist: 
- ENS
``` 
    //name -> coinType-> encodedAddressInBytes
    mapping(bytes32 => mapping(uint256 => bytes)) versionable_addresses;
```

- PNS
```
   //name -> coinType-> string
   mapping(bytes32 => mapping(uint256 => string)) _resolveAddress;
```

### PNS Guardian
The PNS Guardian contract is the entry point for record creation and it's responsible for verification of phone numbers. The Guardian contract is the only authorized contract to access the guardian.

## **Contracts**

The smart contracts are stored under the `contracts` directory.


```ml
contracts/
├── Interface
│   ├── IPNSGuardian.sol * ─ "PNS Guardian Interface"
│   ├── IPNSRegistry.sol * ─ "PNS Registry implementation interface"
│   ├── IPNSResolver.sol * ─ "PNS Resolver implementation interface"
├── PNSGuardian.sol * ─ "PNS Guardian implementation for phone number verification"
├── PNSRegistry.sol * ─ "PNS Registry logic for phone number records"
├── PNSResolver.sol * ─ "Responsible for resolving phone numbers to addresses"
├── PriceOracle.sol * ─ "Handles price calculations and interacts with chainlink oracle for price conversions"
```


## **Documentation**

*PNSRegistry.sol*
-
`PNSRegistry.sol` is initializable and accesscontrolUpgradable. It implements the official IPNSRegistry interface.

### Functions
#### **setPhoneRecord**
`setPhoneRecord` is an external virtual payable function that sets the record for a phoneHash
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to update |
| `Resolver` | `string` | The address the phone number resolves to |

____

#### **setGracePeriod**
`setGracePeriod` is an external function that can only be called by system roles. It updates the contract's grace period.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Time` | `uint256` | The new grace period in seconds. |

____

#### **renew**
`renew` is an external virtual payable function that can renews a phone record. The phone record must have expired and the user must be authorized to modify it.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to renew |

#### modifiers:
|Type     | Description                         |
| :------- | :-------------------------          |
| `authorised(phoneHash)` | Permits modifications only by the owner of the specified phoneHash. |
| `hasExpired(phoneHash)` | Permits the function to run only if phone record is expired. |

____

#### **getVersion**
`getVersion` is an external virtual view function that Gets the current version of the smart contract. 

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `uint32` | The current version of the contract |

____

#### **getRecordFull**
`getRecordFull` is an external view function that retrieves the full record of a phone number, including its owner, expiration date, creation date, and whether it is currently expired or in grace period.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to renew |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `owner` | The address of the current owner of the phone number. |
| `isExpired` | A boolean indicating whether the phone number is currently expired. |
| `isInGracePeriod` | A boolean indicating whether the phone number is currently in the grace period. |
| `expiration` | A timestamp indicating when the phone number will expire. |
| `creation` | A timestamp indicating when the phone number was first registered. |

____

#### **getRecord**
`getRecord` is an external view function that retrieves the phone record for a given phone hash.

#### parameters:
| Parameter  | Type     | Description                 |
| :--------  | :------- | :-------------------------  |
| `Phone Hash` | `bytes32` | The phone hash to retrieve the record for |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `PhoneRecord` | The phone record for the given phone hash. |

____

#### **isRecordVerified**
`isRecordVerified` is a public view function that checks if the specified phoneHash is verified.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to check verification status for |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `bool` | A boolean indicating whether the phone record is verified or not. |

---
#### **transfer**
`transfer` is a public virtual function that transfers ownership of a phoneHash to a new address. Can only be called by the current owner of the phoneHash.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phoneHash to transfer ownership of |
| `New Owner` | `address` | The address of the new owner |

#### modifiers:
|Type     | Description                         |
| :------- | :-------------------------          |
| `authorised(phoneHash)` | Permits modifications only by the owner of the specified phoneHash. |
| `authenticated(phoneHash)` | Permits the function to run only if phone record is still authenticated. |

---
#### **getVerificationStatus**
`getVerificationStatus` is a public view function that retrieves the verification status for a given phone hash from the PNS guardian contract.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to check verification status for |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `bool` | A boolean indicating whether the phone record is verified or not. |

---
#### **recordExists**
`recordExists` is a public view function that returns whether a given phone hash exists in the phone registry
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to check verification status for |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `bool` | A boolean indicating whether a phone record exists. |

---
#### **_hasPassedExpiryTime**
`_hasPassedExpiryTime` is a public view function that checks whether a phone record has passed its  expiry time.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to check |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `bool` | A boolean indicating whether the phonehash has expired. |

---
#### **_hasPassedGracePeriod**
`_hasPassedGracePeriod` is a public view function that checks whether a phone record has passed its grace period.
#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `Phone Hash` | `bytes32` | The phone hash to check |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `bool` | A boolean indicating whether the phone record has passed its grace period. |

*PNSResolver.sol*
-

`PNSResolver.sol` is initializable and OwnableUpgradeable. It inherits the AddressResolver contract.

### Functions 
#### **getVersion**
`getVersion` is an external virtual view function that returns the version number of the contract.

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `uint32` | The version number of the contract. | 

---
#### **setPNSRegistry**
`setPNSRegistry` is an external function that sets the address of the IPNSRegistry contract. This function can only be called by the owner of the contract.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `_newRegistry` | `address` | The address of the new IPNSRegistry contract. |

---
#### **seedResolver**
`seedResolver` is an external function that seeds the resolver address for the specified phone number hash and coin type.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `phoneHash` | `bytes32` | The hash of the phone number to seed the resolver for. |
| `a` | `address` | The address to seed. |

#### modifiers:
|Type     | Description                         |
| :------- | :-------------------------          |
| `registryAuthorised(phoneHash)` | Modifier to check if the message sender is authorized by the IPNSRegistry contract. |

---
#### **getRecord**
`getRecord` is a public view function that returns the record associated with the specified phone number hash.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `phoneHash` | `bytes32` | The hash of the phone number to retrieve the record for.|

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `PhoneRecord` | The PhoneRecord associated with the specified phone number hash. |

---
#### **getOwner**
`getOwner` is a public view function that returns the address that owns the specified phone number.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `phoneHash` | `bytes32` | The specified phoneHash.|

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `address` | address of the owner. |

*PNSGuardian.sol*
-

`PNSGuardian.sol` is initializable and OwnableUpgradeable. It inherits the AddressResolver contract.

### Functions

#### **getVerificationRecord**
`getVerificationRecord` is an external view function that gets the verification record for a phone hash.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `phoneHash` | `bytes32` | Hash of the phone number being verified.|

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `VerificationRecord` | Verification record associated with the phone hash|

---
#### **getVerifiedOwner**
`getVerifiedOwner` is an external view function that gets the verified owner for a phone hash.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `phoneHash` | `bytes32` | Hash of the phone number being verified.|

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `address` | Verified owner associated with the phone hash. |

---
#### **setPNSRegistry**
`setPNSRegistry` is an external function that sets the PNS registry address.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `_registryAddress` | `address` | Address of the PNS registry.|

#### modifiers:
|Type     | Description                         |
| :------- | :-------------------------          |
| `onlyGuardianVerifier` | Modifier that permits modifications only by the PNS guardian verifier. |

---
#### **setGuardianVerifier**
`setGuardianVerifier` is an external function that sets the PNS registry address.

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `_guardianVerifier` | `address` | Address of the guardian verifier.|

#### modifiers:
|Type     | Description                         |
| :------- | :-------------------------          |
| `onlyGuardianVerifier` | Modifier that permits modifications only by the PNS guardian verifier. |

---
#### **verifyPhoneHash**
`verifyPhoneHash` is an external function that verifies a phone number hash

#### parameters:
| Parameter  | Type     | Description                         |
| :--------  | :------- | :-------------------------          |
| `phoneHash` | `bytes32` | Hash of the phone number being verified.|
| `_hashedMessage` | `bytes32` | Hashed message.|
| `status` | `bool` | New verification status.|
| `owner` | `address` | Address of the owner.|
| `_signature` | `bytes` | Signature provided by the off-chain verifier.|

#### modifiers:
|Type     | Description                         |
| :------- | :-------------------------          |
| `onlyGuardianVerifier` | Modifier that permits modifications only by the PNS guardian verifier. |

#### output:
|  Type     | Description                         |
| :------- | :-------------------------          |
| `bool` | A boolean indicating if the verification record has been updated and is no longer a zero-address. |

## **Usage**

## **Prerequisites**

-   [git](https://git-scm.com/downloads)
-   [nodeJS](https://nodejs.org/en/download/)
-   [brew](https://brew.sh/)
-   [foundry](https://getfoundry.sh) - You can run `sh ./setup.sh` to install Foundry and its dependencies.
-   [Hardhat](https://hardhat.org)

## **Setup**

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


## **Deploying**

Create a .env in the root with:

```
PRIVATE_KEY=PRIVATE_KEY
ALCHEMY_API_KEY=
```

Then run:
```
yarn run deploy:ethereum_goerli
```

## **Testing**
To run unit tests:

```shell
yarn run test
```


## **License**

[MIT](LICENSE) Copyright 2022 PNS Labs

## **Contributing**

Contributions are always welcome!

See `contributing.md` for ways to get started

## **Code Of Conduct**
Please adhere to this project's 
[Code of Conduct](code_of_conduct.md) 
