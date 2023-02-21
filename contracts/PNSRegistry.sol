// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ==========  External imports    ==========

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import 'hardhat/console.sol';

// ==========  Internal imports    ==========
import './Interfaces/IPNSRegistry.sol';
import './Interfaces/IPNSResolver.sol';
import './Interfaces/IPNSGuardian.sol';

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);
}

/**
 * @title The contract for phone number service Registry.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSRegistry is inherited which inherits IPNSSchema.
 */

contract PNSRegistry is Initializable, AccessControlUpgradeable, IPNSSchema {
	// using AddressUpgradeable for address payable;
	/// Expiry time value
	uint256 public constant EXPIRY_TIME = 365 days;
	/// Grace period value
	uint256 public gracePeriod;
	/// registry cost
	uint256 public registryCostInUSD;
	/// registry renew cost
	uint256 public registryRenewCostInUSD;
	/// registry renew cost
	address private treasuryAddress;
	/// Oracle feed pricing
	AggregatorInterface public priceFeedContract;

	IPNSGuardian public pnsGuardianContract;
	IPNSResolver public pnsResolverContract;

	/// Mapping state to store mobile phone number record that will be linked to a resolver
	mapping(bytes32 => PhoneRecord) public phoneRegistry;

	/// Create a new role identifier for the minter role
	bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');
	bytes32 public constant VERIFIER_ROLE = keccak256('VERIFIER_ROLE');

	/**
	 * @dev contract initializer function. This function exist because the contract is upgradable.
	 */
	function initialize(
		address _pnsGuardianContract,
		address _pnsResolverContract,
		address _priceAggregator,
		address _verifier,
		address _treasuryAddress
	) external initializer {
		__AccessControl_init();
		//set oracle constant
		// EXPIRY_TIME = 365 days;
		gracePeriod = 60 days;
		treasuryAddress = _treasuryAddress;

		priceFeedContract = AggregatorInterface(_priceAggregator);
		pnsGuardianContract = IPNSGuardian(_pnsGuardianContract);
		pnsResolverContract = IPNSResolver(_pnsResolverContract);

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(VERIFIER_ROLE, _verifier);
	}

	function createRecord(address owner, bytes32 phoneHash) internal {
		PhoneRecord storage record = phoneRegistry[phoneHash];
		record.owner = owner;
		record.expiration = block.timestamp + EXPIRY_TIME;
		record.creation = block.timestamp;
	}

	/**
	 * @dev Sets the record for a phoneHash.
	 * @param phoneHash The phoneHash to update.
	 * @param resolver The address the phone number resolves to.
	 */
	function setPhoneRecord(bytes32 phoneHash, string calldata resolver) external payable virtual {
		_setPhoneRecord(phoneHash, resolver);
	}

	/**
	 * @dev Checks if the specified phoneHash is verified.
	 * @param phoneHash The phoneHash to update.
	 */
	function isRecordVerified(bytes32 phoneHash) public view returns (bool) {
		return getVerificationStatus(phoneHash);
	}

	/**
	 * @dev Transfers ownership of a phoneHash to a new address. Can only be called by the current owner of the phoneHash.
	 * @param phoneHash The phoneHash to transfer ownership of.
	 * @param newOwner The address of the new owner.
	 */
	function transfer(bytes32 phoneHash, address newOwner) public virtual authorised(phoneHash) authenticated(phoneHash) {
		require(newOwner != address(0x0), 'cannot set owner to the zero address');
		require(newOwner != address(this), 'cannot set owner to the registry address');

		phoneRegistry[phoneHash].owner = newOwner;
		emit Transfer(phoneHash, newOwner);
	}

	function _setPhoneRecord(bytes32 phoneHash, string calldata resolver) internal onlyVerified(phoneHash) onlyVerifiedOwner(phoneHash) {
		uint256 ethToUSD = convertETHToUSD(msg.value);
		require(ethToUSD >= registryCostInUSD, 'insufficient balance');
		//create the record in registry
		createRecord(msg.sender, phoneHash);
		//update the address field of eth as default
		pnsResolverContract.setAddr(phoneHash, resolver);
		if (ethToUSD > registryCostInUSD) {
			uint256 refunAmountInUSD = ethToUSD - registryCostInUSD;
			uint256 refundAmountInETH = convertUSDToETH(refunAmountInUSD);
			(bool sent, ) = msg.sender.call{value: refundAmountInETH}('');
			require(sent, 'Transfer failed.');
		}
		// Send the contract balance to the treasury
		withdraw(treasuryAddress, address(this).balance);
		//implement move funds to trwasury
		emit PhoneRecordCreated(phoneHash, resolver, msg.sender);
	}

	// /**
	//  * @dev Sets the resolver address for the specified phoneHash.
	//  * @param phoneHash The phoneHash to update.
	//  * @param resolver The address of the resolver.
	//  * @param label The specified label of the resolver.
	//  */
	// // expired(phoneHash
	// function linkPhoneToWallet(
	// 	bytes32 phoneHash,
	// 	address resolver,
	// 	string memory label
	// ) public virtual authorised(phoneHash) authenticated(phoneHash) {
	// 	_linkphoneHashToWallet(phoneHash, resolver, label);
	// 	emit PhoneLinked(phoneHash, resolver);
	// }

	// /**
	//  * @dev Renew a phone record.
	//  * @param phoneHash The phoneHash.
	//  */
	// function renew(bytes32 phoneHash) external payable virtual authorised(phoneHash) hasExpiryOf(phoneHash) {
	// 	//convert to wei
	// 	uint256 ethToUSD = convertETHToUSD(msg.value);
	// 	require(ethToUSD >= registryRenewCostInUSD, 'insufficient balance');
	// 	PhoneRecord storage recordData = records[phoneHash];
	// 	bool _timeHasPassedExpiryTime = _hasPassedExpiryTime(phoneHash);
	// 	bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);

	// 	require(recordData.exists, 'only an existing phone record can be renewed');
	// 	require(_timeHasPassedExpiryTime && !_hasExhaustedGracePeriod, 'only a phone record currently in grace period can be renewed');

	// 	// recordData.isInGracePeriod = false;
	// 	// recordData.isExpired = false;
	// 	recordData.expirationTime = block.timestamp + EXPIRY_TIME;

	// 	//refund user if excessive
	// 	if (ethToUSD > registryRenewCostInUSD) {
	// 		uint256 refunAmountInUSD = ethToUSD - registryRenewCostInUSD;
	// 		uint256 refundAmountInETH = convertUSDToETH(refunAmountInUSD);
	// 		(bool sent, ) = msg.sender.call{value: refundAmountInETH}('');
	// 		require(sent, 'Transfer failed.');
	// 	}

	// 	//implement move money(ETH) to treasury
	// 	emit PhoneRecordRenewed(phoneHash);
	// }

	// /**
	//  * @dev Claims an already existing but expired phone record, and sets a completely new resolver.
	//  * @param phoneHash The phoneHash.
	//  * @param resolver The address the phone number resolves to.
	//  * @param label The specified label of the resolver.
	//  */
	// function claimExpiredPhoneRecord(
	// 	bytes32 phoneHash,
	// 	address resolver,
	// 	string memory label
	// ) external payable virtual hasExpiryOf(phoneHash) {
	// 	PhoneRecord storage recordData = phoneRegistry[phoneHash];
	// 	bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);

	// 	require(recordData.exists, 'only an existing phone record can be claimed');
	// 	require(_hasExhaustedGracePeriod, 'only an expired phone record can be claimed');

	// 	delete phoneRegistry[phoneHash];
	// 	delete resolverphoneRegistry[phoneHash];

	// 	return _setPhoneRecord(phoneHash, msg.sender, resolver, label);
	// }

	/**
	 * @dev Gets the current version of the smart contract.
	 * @return uint32 The current version
	 */
	function getVersion() external view virtual returns (uint32) {
		return 1;
	}

	// /**
	//  * @dev Updates the expiry time of a phone record.
	//  * @param time The new expiry time in seconds.
	//  */
	// function setExpiryTime(uint256 time) external onlySystemRoles {
	// 	EXPIRY_TIME = time;
	// 	emit ExpiryTimeUpdated(msg.sender, time);
	// }

	/**
	 * @dev Updates the grace period.
	 * @param time The new grace period in seconds.
	 */
	function setGracePeriod(uint256 time) external onlySystemRoles {
		gracePeriod = time;
		emit GracePeriodUpdated(msg.sender, time);
	}

	function setRegistryCost(uint256 _registryCostInUSD) external onlySystemRoles {
		//double check : convert amount entered to wei value;
		registryCostInUSD = _registryCostInUSD;
	}

	function setRegistryRenewCost(uint256 _registryRenewCostInUSD) external onlySystemRoles {
		//double check : convert amount entered to wei value;
		registryRenewCostInUSD = _registryRenewCostInUSD;
	}

	function verifyPhone(
		bytes32 phoneHash,
		bool status,
		bytes calldata signature
	) external {
		bool ok = pnsGuardianContract.setVerificationStatus(phoneHash, status, signature);
		require(ok, 'verification failed');
		emit PhoneNumberVerified(phoneHash, status);
	}

	/**
	 * @dev Returns the hash for a given phoneHash
	 * @param phoneHash The phoneHash to hash
	 * @return The ENS node hash.
	 */
	function _hash(bytes32 phoneHash) internal pure returns (bytes32) {
		return keccak256(abi.encode(phoneHash));
	}

	function convertETHToUSD(uint256 ethAmount) public view returns (uint256) {
		uint256 ethPrice = getEtherPriceInUSD();
		uint256 ethAmountInUSD = (ethAmount * ethPrice) / 10**18;
		return uint256(ethAmountInUSD);
	}

	function convertUSDToETH(uint256 usdAmount) public view returns (uint256) {
		uint256 ethPrice = getEtherPriceInUSD();
		uint256 ethAmountInUSD = (usdAmount * 10**18) / ethPrice;
		return uint256(ethAmountInUSD);
	}

	/**
	 * @dev Returns the latest price
	 */

	function getEtherPriceInUSD() public view returns (uint256) {
		int256 answer = priceFeedContract.latestAnswer();
		// Chainlink returns 8 decimal places so we convert to wei
		return uint256(answer * 10**10);
	}

	// /**
	//  * @dev Returns the PhoneRecord data linked to the specified phone number hash.
	//  * @param phoneHash The specified phoneHash.
	//  */
	// function getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory) {
	// 	PhoneRecord memory recordData = phoneRegistry[phoneHash];
	// 	require(recordData.exists, 'phone record not found');
	// 	bool _isInGracePeriod = _hasPassedExpiryTime(phoneHash);
	// 	bool _isExpired = _hasPassedGracePeriod(phoneHash);

	// 	return
	// 		PhoneRecord(
	// 			recordData.owner,
	// 			recordData.phoneHash,
	// 			recordData.exists,
	// 			_isInGracePeriod,
	// 			_isExpired,
	// 			recordData.expirationTime,
	// 			recordData.createdAt
	// 		);
	// }

	function getVerificationStatus(bytes32 phoneHash) public view returns (bool) {
		bool status = pnsGuardianContract.getVerificationStatus(phoneHash);
		return status;
	}

	/**
	 * @dev Returns whether a record has been imported to the registry.
	 * @param phoneHash The specified phoneHash.
	 * @return Bool if record exists
	 */
	function recordExists(bytes32 phoneHash) public view returns (bool) {
		return phoneRegistry[phoneHash].owner != address(0);
	}

	/**
	 * @dev Returns the expiry state of an existing phone record.
	 * @param phoneHash The specified phoneHash.
	 */
	function _hasPassedExpiryTime(bytes32 phoneHash) internal view returns (bool) {
		return block.timestamp > phoneRegistry[phoneHash].expiration;
	}

	/**
	 * @dev Returns the grace period state of an existing phone record.
	 * @param phoneHash The specified phoneHash.
	 */
	function _hasPassedGracePeriod(bytes32 phoneHash) internal view returns (bool) {
		return block.timestamp > (phoneRegistry[phoneHash].expiration + gracePeriod);
	}

	/**
	 * @dev Withdraws funds from the protocol contract
	 * @param amount The amount to withdraw
	 * @param _recipient The recipient of the funds
	 */
	function withdraw(address _recipient, uint256 amount) external onlySystemRoles {
		require(amount > 0, 'amount must be greater than zero');
		(bool success, ) = _recipient.call{value: amount}('');
		require(success, 'Transfer failed.');
		emit WithdrawalSuccessful(_recipient, amount);
	}

	//============MODIFIERS==============
	/**
	 * @dev Permits modifications only by the owner of the specified phoneHash.
	 * @param phoneHash The phoneHash of the record owner to be compared.
	 */
	modifier authorised(bytes32 phoneHash) {
		require(msg.sender == phoneRegistry[phoneHash].owner, 'caller is not authorised');
		_;
	}

	/**
	 * @dev Permits the function to run only if phone record is not expired.
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
	// modifier expired(bytes32 phoneHash) {
	// 	bool _hasExpired = _hasPassedExpiryTime(phoneHash);
	// 	if (_hasExpired) {
	// 		PhoneRecord storage recordData = phoneRegistry[phoneHash];
	// 		recordData.isInGracePeriod = true;
	// 		emit PhoneRecordEnteredGracePeriod(phoneHash);
	// 	}
	// 	_;
	// }

	/**
	 * @dev Permits the function to run only if phone record is still authenticated.
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
	modifier authenticated(bytes32 phoneHash) {
		bool expiry = _hasPassedExpiryTime(phoneHash);
		require(!expiry, 'grace period passed');
		_;
	}

	modifier onlyVerified(bytes32 phoneHash) {
		bool status = pnsGuardianContract.getVerificationStatus(phoneHash);
		require(status, 'phone record is not verified');
		_;
	}
	modifier onlyVerifiedOwner(bytes32 phoneHash) virtual {
		address owner = pnsGuardianContract.getVerifiedOwner(phoneHash);
		require(owner == msg.sender, 'caller is not verified owner');
		_;
	}

	modifier onlySystemRoles() {
		require(hasRole(MAINTAINER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not allowed to execute function');
		_;
	}

	modifier onlyVerifierRoles() {
		require(hasRole(VERIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'NON_VERIFIER_ROLE: Not allowed to execute function');
		_;
	}
}
