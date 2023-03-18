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
import 'hardhat/console.sol';

/**
 * @title The contract for phone number service Registry.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSRegistry is inherited which inherits IPNSSchema.
 */

contract PNSRegistry is Initializable, AccessControlUpgradeable, IPNSRegistry {
	// using AddressUpgradeable for address payable;

	//============STATE VARIABLES==============
	// Expiry time value
	uint256 public constant EXPIRY_TIME = 365 days;
	// Grace period value
	uint256 public gracePeriod;

	// Registry cost in USD
	uint256 public registryCostInUSD;
	// Registry renew cost in USD
	uint256 public registryRenewCostInUSD;
	// Address of the treasury
	address public treasuryAddress;

	// Oracle feed pricing
	IPriceConverter public priceConverter;
	// Address of the PNS guardian contract
	IPNSGuardian public pnsGuardian;
	// Address of the PNS resolver contract
	IPNSResolver public pnsResolver;

	// Mapping to store phone number record linked to a resolver
	mapping(bytes32 => PhoneRecord) public phoneRegistry;

	// Create a new role identifier for the maintainer role
	bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

	//============EXTERNAL FUNCTIONS==============

	/**
	 * @dev Initializes the contract.
	 * @param _pnsGuardian Address of the PNSGuardian contract.
	 * @param _priceConverter Address of the IPriceConverter contract.
	 * @param _treasuryAddress Address of the treasury.
	 */
	function initialize(address _pnsGuardian, address _priceConverter, address _treasuryAddress) external initializer {
		__AccessControl_init();
		//set oracle constant
		gracePeriod = 60 days;

		priceConverter = IPriceConverter(_priceConverter);
		pnsGuardian = IPNSGuardian(_pnsGuardian);
		treasuryAddress = _treasuryAddress;

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/**
	 * @dev Sets the record for a phone number hash.
	 * @param phoneHash The phone number hash to update.
	 * @param resolver The address the phone number resolves to.
	 */
	function setPhoneRecord(bytes32 phoneHash, address resolver) external payable virtual {
		_setPhoneRecord(phoneHash, resolver);
	}

	/**
	 * @dev Updates the grace period.
	 * @param time The new grace period in seconds.
	 */
	function setGracePeriod(uint256 time) external onlySystemRoles {
		gracePeriod = time;
		emit changeGracePeriod(msg.sender, time);
	}

	/**
	 * @dev Sets the registry cost in USD.
	 * @param _registryCostInUSD The new registry cost in USD.
	 */
	function setRegistryCost(uint256 _registryCostInUSD) external onlySystemRoles {
		//double check : convert amount entered to wei value;
		registryCostInUSD = _registryCostInUSD;
	}

	/**
	 * @dev Sets the cost in USD for renewing a registry.
	 * @param _registryRenewCostInUSD The new cost for renewing a registry in USD.
	 * @notice The amount entered will be converted to its corresponding value in wei.
	 * @notice Only system roles are allowed to call this function.
	 */
	function setRegistryRenewCost(uint256 _registryRenewCostInUSD) external onlySystemRoles {
		//double check : convert amount entered to wei value;
		registryRenewCostInUSD = _registryRenewCostInUSD;
	}

	/**
	 * @dev Sets the treasury address.
	 * @param _treasuryAddress The new treasury address.
	 * @notice Only system roles are allowed to call this function.
	 */
	function setTreasuryAddress(address _treasuryAddress) external onlySystemRoles {
		treasuryAddress = _treasuryAddress;
	}

	/**
	 * @dev Sets the new PNS guardian address.
	 * @param _newGuardianAddress The new PNS guardian address.
	 * @notice Only system roles are allowed to call this function.
	 */
	function setGuardian(address _newGuardianAddress) external onlySystemRoles {
		pnsGuardian = IPNSGuardian(_newGuardianAddress);
	}

	/**
	 * @dev Sets the new PNS resolver address.
	 * @param _newResolverAddress The new PNS resolver address.
	 * @notice Only system roles are allowed to call this function.
	 */
	function setResolver(address _newResolverAddress) external onlySystemRoles {
		pnsResolver = IPNSResolver(_newResolverAddress);
	}

	/**
	 * @dev Renew a phone record.
	 * @param phoneHash The phoneHash.
	 * @notice The phone record must have expired and the user must be authorized to modify it.
	 */
	function renew(bytes32 phoneHash) external payable virtual authorised(phoneHash) hasExpired(phoneHash) {
		//convert to wei
		uint256 ethToUSD = priceConverter.convertETHToUSD(msg.value);
		require(ethToUSD >= registryRenewCostInUSD, 'insufficient balance');

		//move to  DAO treasury
		uint256 registryRenewCostInETH = priceConverter.convertUSDToETH(registryRenewCostInUSD);
		toTreasury(registryRenewCostInETH);

		phoneRegistry[phoneHash].expiration = uint48(block.timestamp + EXPIRY_TIME);
		emit PhoneRecordRenewed(phoneHash);

		//refund user if excessive
		if (ethToUSD > registryRenewCostInUSD) {
			uint256 refunAmountInUSD = ethToUSD - registryRenewCostInUSD;
			uint256 refundAmountInETH = priceConverter.convertUSDToETH(refunAmountInUSD);
			(bool sent, ) = msg.sender.call{value: refundAmountInETH}('');
			require(sent, 'Transfer failed.');
		}
	}

	/**
	 * @dev Gets the current version of the smart contract.
	 * @return uint32 The current version
	 */
	function getVersion() external view virtual returns (uint32) {
		return 1;
	}

	/**
	* @dev Retrieves the full record of a phone number, including its owner, expiration date, creation date, and whether it is currently expired or in grace period.
	* @param phoneHash The hash of the phone number to retrieve the record for.
	* @return owner The address of the current owner of the phone number.
	* @return isExpired A boolean indicating whether the phone number is currently expired.
	* @return isInGracePeriod A boolean indicating whether the phone number is currently in the grace period.
	* @return expiration The timestamp indicating when the phone number will expire.
	* @return creation The timestamp indicating when the phone number was first registered.
	*/
	function getRecordFull(
		bytes32 phoneHash
	) external view returns (address owner, bool isExpired, bool isInGracePeriod, uint256 expiration, uint256 creation) {
		recordExists(phoneHash);
		PhoneRecord memory record = phoneRegistry[phoneHash];
		isInGracePeriod = _hasPassedExpiryTime(phoneHash);
		isExpired = _hasPassedGracePeriod(phoneHash);
		expiration = record.expiration;
		creation = record.creation;
		owner = record.owner;
	}

	/**
	 * @dev Retrieves the phone record for a given phone hash.
	 * @param phoneHash The phone hash to retrieve the record for.
	 * @return The phone record for the given phone hash.
	 */
	function getRecord(bytes32 phoneHash) external view returns (PhoneRecord memory) {
		return phoneRegistry[phoneHash];
	}

	/**
	 * @dev Allows the system roles to withdraw funds from the contract and send them to a recipient.
	 * @param _recipient The address to send the funds to.
	 * @param amount The amount of funds to send.
	 */
	function withdraw(address _recipient, uint256 amount) external onlySystemRoles {
		require(amount > 0, 'amount must be greater than zero');
		(bool success, ) = _recipient.call{value: amount}('');
		require(success, 'Transfer failed.');
		emit WithdrawalSuccessful(_recipient, amount);
	}

	//============PUBLIC FUNCTIONS==============

	/**
	 * @dev Transfers ownership of a phoneHash to a new address. Can only be called by the current owner of the phoneHash.
	 * @param phoneHash The phoneHash to transfer ownership of.
	 * @param newOwner The address of the new owner.
	 */
	function transfer(bytes32 phoneHash, address newOwner) public virtual authorised(phoneHash) notExpired(phoneHash) {
		require(newOwner != address(0x0), 'cannot set owner to the zero address');
		require(newOwner != address(this), 'cannot set owner to the registry address');

		phoneRegistry[phoneHash].owner = newOwner;
		emit Transfer(phoneHash, newOwner);
	}

	/**
	 * @dev Retrieves the verification status for a given phone hash from the PNS guardian contract.
	 * @param phoneHash The phone hash to retrieve the verification status for.
	 * @return A boolean indicating the verification status for the given phone hash.
	 */
	function getVerificationStatus(bytes32 phoneHash) public view returns (bool) {
		bool status = pnsGuardian.getVerificationStatus(phoneHash);
		return status;
	}

	/**
	 * @dev Checks if the specified phoneHash is verified.
	 * @param phoneHash The phone hash to check verification status for.
	 * @return A boolean indicating whether the phone record is verified or not.
	 */
	function isRecordVerified(bytes32 phoneHash) public view returns (bool) {
		return getVerificationStatus(phoneHash);
	}

	/**
	 * @dev Returns whether a given phone hash exists in the phone registry
	 * @param phoneHash The specified phoneHash.
	 * @return A boolean indicating whether a phone record exists.
	 */
	function recordExists(bytes32 phoneHash) public view returns (bool) {
		return phoneRegistry[phoneHash].owner != address(0);
	}

	/**
	 * @dev Checks whether a phone record has passed its expiry time.
	 * @param phoneHash The specified phoneHash.
	 * @return A boolean indicating whether the phonehash has expired.
	 */
	function _hasPassedExpiryTime(bytes32 phoneHash) public view returns (bool) {
		return block.timestamp > phoneRegistry[phoneHash].expiration;
	}

	/**
	 * @dev Checks whether a phone record has passed its grace period.
	 * @param phoneHash The hash of the phone number to check.
	 * @return A boolean indicating whether the phone record has passed its grace period.
	 */
	function _hasPassedGracePeriod(bytes32 phoneHash) public view returns (bool) {
		return block.timestamp > (phoneRegistry[phoneHash].expiration + gracePeriod);
	}

	//============INTERNAL FUNCTIONS==============

	/**
	 * @dev Creates a phone record with the specified owner and phone number hash.
	 * @param owner The owner address of the phone record.
	 * @param phoneHash The hash of the phone number to create the record for.
	 */
	function createRecord(address owner, bytes32 phoneHash) internal {
		PhoneRecord storage record = phoneRegistry[phoneHash];
		record.owner = owner;
		record.expiration = uint48(block.timestamp + EXPIRY_TIME);
		record.creation = uint48(block.timestamp);
	}

	/**
	 * @dev Sets the phone record with the specified phone number hash to the specified resolver address.
	 * @param phoneHash The hash of the phone number to set the record for.
	 * @param resolver The resolver address to set for the phone record.
	 */
	function _setPhoneRecord(bytes32 phoneHash, address resolver) internal onlyVerified(phoneHash) onlyVerifiedOwner(phoneHash) {
		uint256 ethToUSD = priceConverter.convertETHToUSD(msg.value);
		require(ethToUSD >= registryCostInUSD, 'insufficient balance');
		//create the record in registry
		createRecord(msg.sender, phoneHash);
		//update the address field of eth as default
		pnsResolver.seedResolver(phoneHash, resolver);

		// Send the registry cost to the treasury
		uint256 registryCostInEth = priceConverter.convertUSDToETH(registryCostInUSD);
		toTreasury(registryCostInEth);

		emit PhoneRecordCreated(phoneHash, resolver, msg.sender);
		//  address(pnsResolver).call(abi.encodeWithSignature(
		// 	"seedResolver(bytes32, address)", phoneHash, resolver));

		// Refund remaining balance to caller
		if (ethToUSD > registryCostInUSD) {
			uint256 refunAmountInUSD = ethToUSD - registryCostInUSD;
			uint256 refundAmountInETH = priceConverter.convertUSDToETH(refunAmountInUSD);
			(bool sent, ) = msg.sender.call{value: refundAmountInETH}('');
			require(sent, 'Transfer failed.');
		}
	}

	/**
	 * @dev Sends the specified amount of Ether to the DAO treasury.
	 * @param amount The amount of Ether to send to the treasury.
	 */
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
	 * @dev Permits the function to run only if phone record is expired.
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
	modifier hasExpired(bytes32 phoneHash) {
		require(_hasPassedExpiryTime(phoneHash), 'cannot proceed: record not expired');
		_;
	}

	/**
	 * @dev Permits the function to run only if phone record is not expired.
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
	modifier notExpired(bytes32 phoneHash) {
		require(!_hasPassedGracePeriod(phoneHash), 'cannot proceed: record expired');
		_;
	}

	/**
	 * @dev Modifier to check if the phone record is verified
	 * @param phoneHash The hash of the phone number record to check
	 */
	modifier onlyVerified(bytes32 phoneHash) {
		bool status = pnsGuardian.getVerificationStatus(phoneHash);
		require(status, 'phone record is not verified');
		_;
	}

	/**
	 * @dev Modifier to check if the caller is the verified owner of the phone record
	 * @param phoneHash The hash of the phone number record to check
	 */
	modifier onlyVerifiedOwner(bytes32 phoneHash) virtual {
		address owner = pnsGuardian.getVerifiedOwner(phoneHash);
		require(owner == msg.sender, 'caller is not verified owner');
		_;
	}

	/**
	 * @dev Modifier to check if the caller has system roles (maintainer or default admin)
	 */
	modifier onlySystemRoles() {
		require(hasRole(MAINTAINER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not allowed to execute function');
		_;
	}
}
