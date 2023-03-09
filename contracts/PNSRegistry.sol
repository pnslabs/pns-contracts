// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ==========  External imports    ==========

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import 'hardhat/console.sol';

// ==========  Internal imports    ==========
import './Interfaces/pns/IPNSRegistry.sol';
import './Interfaces/pns/IPNSResolver.sol';
import './Interfaces/pns/IPNSGuardian.sol';
import './Interfaces/dependencies/IPriceConverter.sol';

/**
 * @title The contract for phone number service Registry.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSRegistry is inherited which inherits IPNSSchema.
 */

contract PNSRegistry is Initializable, AccessControlUpgradeable, IPNSRegistry {
	// using AddressUpgradeable for address payable;
	/// Expiry time value
	uint256 public constant EXPIRY_TIME = 365 days;
	/// Grace period value
	uint256 public gracePeriod;
	/// registry cost
	uint256 public registryCostInUSD;
	/// registry renew cost
	uint256 public registryRenewCostInUSD;

	address public treasuryAddress;
	/// Oracle feed pricing
	IPriceConverter public priceConverter;
	IPNSGuardian public pnsGuardian;
	IPNSResolver public pnsResolver;

	/// Mapping state to store mobile phone number record that will be linked to a resolver
	mapping(bytes32 => PhoneRecord) public phoneRegistry;

	/// Create a new role identifier for the minter role
	bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

	/**
	 * @dev contract initializer function. This function exist because the contract is upgradable.
	 */
	function initialize(
		address _pnsGuardian,
		address _priceConverter,
		address _treasuryAddress
	) external initializer {
		__AccessControl_init();
		//set oracle constant
		gracePeriod = 60 days;

		priceConverter = IPriceConverter(_priceConverter);
		pnsGuardian = IPNSGuardian(_pnsGuardian);
		treasuryAddress = _treasuryAddress;

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

	/**
	 * @dev Updates the grace period.
	 * @param time The new grace period in seconds.
	 */
	function setGracePeriod(uint256 time) external onlySystemRoles {
		gracePeriod = time;
		emit changeGracePeriod(msg.sender, time);
	}

	function setRegistryCost(uint256 _registryCostInUSD) external onlySystemRoles {
		//double check : convert amount entered to wei value;
		registryCostInUSD = _registryCostInUSD;
	}

	function setRegistryRenewCost(uint256 _registryRenewCostInUSD) external onlySystemRoles {
		//double check : convert amount entered to wei value;
		registryRenewCostInUSD = _registryRenewCostInUSD;
	}

	function setTreasuryAddress(address _treasuryAddress) external onlySystemRoles {
		treasuryAddress = _treasuryAddress;
	}

	function setGuardian(address _newGuardianAddress) external onlySystemRoles {
		pnsGuardian = IPNSGuardian(_newGuardianAddress);
	}

	function setResolver(address _newResolverAddress) external onlySystemRoles {
		pnsResolver = IPNSResolver(_newResolverAddress);
	}

	/**
	 * @dev Renew a phone record.
	 * @param phoneHash The phoneHash.
	 */
	function renew(bytes32 phoneHash) external payable virtual authorised(phoneHash) notExpired(phoneHash) {
		//convert to wei
		uint256 ethToUSD = priceConverter.convertETHToUSD(msg.value);
		require(ethToUSD >= registryRenewCostInUSD, 'insufficient balance');

		//refund user if excessive
		if (ethToUSD > registryRenewCostInUSD) {
			uint256 refunAmountInUSD = ethToUSD - registryRenewCostInUSD;
			uint256 refundAmountInETH = priceConverter.convertUSDToETH(refunAmountInUSD);
			(bool sent, ) = msg.sender.call{value: refundAmountInETH}('');
			require(sent, 'Transfer failed.');
		}
		//move to  DAO treasury
		toTreasury(registryRenewCostInUSD);
		phoneRegistry[phoneHash].expiration = uint48(block.timestamp + EXPIRY_TIME);
		emit PhoneRecordRenewed(phoneHash);
	}

	/**
	 * @dev Gets the current version of the smart contract.
	 * @return uint32 The current version
	 */
	function getVersion() external view virtual returns (uint32) {
		return 1;
	}

	/**
	 * @dev Returns the PhoneRecord data linked to the specified phone number hash.
	 * @param phoneHash The specified phoneHash.
	 */
	function getRecordFull(bytes32 phoneHash)
		external
		view
		returns (
			address owner,
			bool isExpired,
			bool isInGracePeriod,
			uint256 expiration,
			uint256 creation
		)
	{
		recordExists(phoneHash);
		PhoneRecord memory record = phoneRegistry[phoneHash];
		isInGracePeriod = _hasPassedExpiryTime(phoneHash);
		isExpired = _hasPassedGracePeriod(phoneHash);
		expiration = record.expiration;
		creation = record.creation;
		owner = record.owner;
	}

	function getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory) {
		return phoneRegistry[phoneHash];
	}

	function getVerificationStatus(bytes32 phoneHash) public view returns (bool) {
		bool status = pnsGuardian.getVerificationStatus(phoneHash);
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
	function _hasPassedExpiryTime(bytes32 phoneHash) public view returns (bool) {
		return block.timestamp > phoneRegistry[phoneHash].expiration;
	}

	/**
	 * @dev Returns the grace period state of an existing phone record.
	 * @param phoneHash The specified phoneHash.
	 */
	function _hasPassedGracePeriod(bytes32 phoneHash) public view returns (bool) {
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

	function createRecord(address owner, bytes32 phoneHash) internal {
		PhoneRecord storage record = phoneRegistry[phoneHash];
		record.owner = owner;
		record.expiration = uint48(block.timestamp + EXPIRY_TIME);
		record.creation = uint48(block.timestamp);
	}

	function _setPhoneRecord(bytes32 phoneHash, string calldata resolver) internal onlyVerified(phoneHash) onlyVerifiedOwner(phoneHash) {
		uint256 ethToUSD = priceConverter.convertETHToUSD(msg.value);
		require(ethToUSD >= registryCostInUSD, 'insufficient balance');
		//create the record in registry
		createRecord(msg.sender, phoneHash);
		//update the address field of eth as default
		pnsResolver.setAddr(phoneHash, resolver);
		if (ethToUSD > registryCostInUSD) {
			uint256 refunAmountInUSD = ethToUSD - registryCostInUSD;
			uint256 refundAmountInETH = priceConverter.convertUSDToETH(refunAmountInUSD);
			(bool sent, ) = msg.sender.call{value: refundAmountInETH}('');
			require(sent, 'Transfer failed.');
		}
		// Send the contract balance to the treasury
		toTreasury(registryCostInUSD);
		//implement move funds to trwasury
		emit PhoneRecordCreated(phoneHash, resolver, msg.sender);
	}

	function toTreasury(uint256 amount) internal {
		(bool sent, ) = treasuryAddress.call{value: amount}('');
		require(sent, 'Transfer failed.');
	}

	/**
	 * @dev Returns the hash for a given phoneHash
	 * @param phoneHash The phoneHash to hash
	 * @return The ENS node hash.
	 */
	function _hash(bytes32 phoneHash) internal pure returns (bytes32) {
		return keccak256(abi.encode(phoneHash));
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
	modifier notExpired(bytes32 phoneHash) {
		require(!_hasPassedExpiryTime(phoneHash), 'cannot renew expired record');
		_;
	}

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
		bool status = pnsGuardian.getVerificationStatus(phoneHash);
		require(status, 'phone record is not verified');
		_;
	}

	modifier onlyVerifiedOwner(bytes32 phoneHash) virtual {
		address owner = pnsGuardian.getVerifiedOwner(phoneHash);
		require(owner == msg.sender, 'caller is not verified owner');
		_;
	}

	modifier onlySystemRoles() {
		require(hasRole(MAINTAINER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not allowed to execute function');
		_;
	}
}
