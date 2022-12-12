// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ==========  External imports    ==========

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

// ==========  Internal imports    ==========
import './Interfaces/IPNSRegistry.sol';
import './PNSGuardian.sol';

/**
 * @title The contract for phone number service Registry.
 * @author PNS foundation core
 * @notice You can only interact with the public functions and state definitions.
 * @dev The interface IPNSRegistry is inherited which inherits IPNSSchema.
 */
contract PNSRegistry is Initializable, AccessControlUpgradeable, PNSGuardian {
    /// Expiry time value
    uint256 public expiryTime;
    /// Grace period value
    uint256 public gracePeriod;
    /// registry cost
    uint256 public registryCost;
    /// registry renew cost
    uint256 public registryRenewCost;

    address priceFeed;

    /// Create a new role identifier for the minter role
    // bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

    /// Mapping state to store resolver record
    mapping(string => ResolverRecord) resolverRecordMapping;

    /// Mapping state to store mobile phone number record that will be linked to a resolver
    mapping(bytes32 => PhoneRecord) records;

    /**
     * @dev logs the event when a phoneHash record is created.
	 * @param phoneHash The phoneHash to be linked to the record.
	 * @param wallet The resolver (address) of the record
	 * @param owner The address of the owner
	 */
    event PhoneRecordCreated(bytes32 indexed phoneHash, address indexed wallet, address indexed owner);

    /**
     * @dev logs when there is a transfer of ownership of a phoneHash to a new address
	 * @param phoneHash The phoneHash of the record to be updated.
	 * @param owner The address of the owner
	 */
    event Transfer(bytes32 indexed phoneHash, address indexed owner);

    /**
     * @dev logs when a resolver address is linked to a specified phoneHash.
	 * @param phoneHash The phoneHash of the record to be linked.
	 * @param wallet The address of the resolver.
	 */
    event PhoneLinked(bytes32 indexed phoneHash, address indexed wallet);

    /**
     * @dev logs when phone record has entered a grace period.
	 * @param phoneHash The phoneHash of the record.
	 */
    event PhoneRecordEnteredGracePeriod(bytes32 indexed phoneHash);

    /**
     * @dev logs when phone record has expired.
	 * @param phoneHash The phoneHash of the record.
	 */
    event PhoneRecordExpired(bytes32 indexed phoneHash);

    /**
     * @dev logs when phone record is re-authenticated.
	 * @param phoneHash The phoneHash of the record.
	 */
    event PhoneRecordRenewed(bytes32 indexed phoneHash);

    /**
     * @dev logs when phone record is claimed.
	 * @param updater Who made the call
	 * @param expiryTime The new expiry time in seconds.
	 */
    event ExpiryTimeUpdated(address indexed updater, uint256 expiryTime);

    /**
     * @dev logs when phone record is claimed.
	 * @param updater Who made the call
	 * @param gracePeriod The new grace period in seconds.
	 *
	 */
    event GracePeriodUpdated(address indexed updater, uint256 gracePeriod);

    /**
     * @dev contract initializer function. This function exist because the contract is upgradable.
	 */
    function initialize(address _guardianVerifier, address _priceAggregator) external initializer {
        __AccessControl_init();

        //set oracle constant
        expiryTime = 365 days;
        gracePeriod = 60 days;

        priceFeed = _priceAggregator;
        this.setGuardianVerifier(_guardianVerifier);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sets the record for a phoneHash.
	 * @param phoneHash The phoneHash to update.
	 * @param resolver The address the phone number resolves to.
	 * @param label The specified label of the resolver.
	 */
    function setPhoneRecord(
        bytes32 phoneHash,
        address resolver,
        string memory label
    ) external virtual {
        return _setPhoneRecord(phoneHash, msg.sender, resolver, label);
    }

    function isRecordVerified(bytes32 phoneHash) public view returns (bool) {
        return records[phoneHash].isVerified;
    }

    /**
     * @dev Transfers ownership of a phoneHash to a new address. Can only be called by the current owner of the phoneHash.
	 * @param phoneHash The phoneHash to transfer ownership of.
	 * @param owner The address of the new owner.
	 */
    function setOwner(bytes32 phoneHash, address owner) public virtual authorised(phoneHash) expired(phoneHash) authenticated(phoneHash) {
        _setOwner(phoneHash, owner);
        emit Transfer(phoneHash, owner);
    }

    /**
     * @dev Sets the resolver address for the specified phoneHash.
	 * @param phoneHash The phoneHash to update.
	 * @param resolver The address of the resolver.
	 * @param label The specified label of the resolver.
	 */
    function linkPhoneToWallet(
        bytes32 phoneHash,
        address resolver,
        string memory label
    ) public virtual authorised(phoneHash) expired(phoneHash) authenticated(phoneHash) {
        _linkphoneHashToWallet(phoneHash, resolver, label);
        emit PhoneLinked(phoneHash, resolver);
    }

    /**
     * @dev Renew a phone record.
	 * @param phoneHash The phoneHash.
	 */
    function renew(bytes32 phoneHash) external payable virtual authorised(phoneHash) hasExpiryOf(phoneHash) {

        require(msg.value >= convertAmountToETH(registryRenewCost), 'fee must be greater than or equal to the registry renewal fee');
        PhoneRecord storage recordData = records[phoneHash];
        bool _timeHasPassedExpiryTime = _hasPassedExpiryTime(phoneHash);
        bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);
        require(recordData.exists, 'only an existing phone record can be renewed');
        require(_timeHasPassedExpiryTime && !_hasExhaustedGracePeriod, 'only a phone record currently in grace period can be renewed');

        recordData.isInGracePeriod = false;
        recordData.isExpired = false;
        recordData.expirationTime = block.timestamp + expiryTime;

        (bool success,) = address(this).call{value : msg.value}('');

        require(success, 'Transfer failed.');

        if (msg.value > convertAmountToETH(registryRenewCost)) {
            (bool sent,) = msg.sender.call{value : msg.value - convertAmountToETH(registryRenewCost)}('');
            require(sent, 'Transfer failed.');
        }


        emit PhoneRecordRenewed(phoneHash);
    }
    function verifyUser(bytes32 phoneHash, bytes32 hashedMessage, bool status, bytes memory signature) external {
        this.setVerificationStatus(phoneHash, hashedMessage,  status, signature);
    }
    /**
     * @dev Claims an already existing but expired phone record, and sets a completely new resolver.
	 * @param phoneHash The phoneHash.
	 * @param owner The address of the new owner.
	 * @param resolver The address the phone number resolves to.
	 * @param label The specified label of the resolver.
	 */
    function claimExpiredPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) external payable virtual hasExpiryOf(phoneHash) {
        PhoneRecord storage recordData = records[phoneHash];
        bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);

        require(recordData.exists, 'only an existing phone record can be claimed');
        require(_hasExhaustedGracePeriod, 'only an expired phone record can be claimed');

        delete records[phoneHash];

        return _setPhoneRecord(phoneHash, owner, resolver, label);
    }

    /**
     * @dev Gets the current version of the smart contract.
	 * @return uint32 The current version
	 */
    function getVersion() external view virtual returns (uint32) {
        return 1;
    }

    function _setOwner(bytes32 phoneHash, address owner) internal virtual returns (bytes32) {
        require(owner != address(0x0), 'cannot set owner to the zero address');
        require(owner != address(this), 'cannot set owner to the registry address');
        records[phoneHash].owner = owner;
        return phoneHash;
    }

    /**
     * @dev Updates the expiry time of a phone record.
	 * @param time The new expiry time in seconds.
	 */
    function setExpiryTime(uint256 time) external onlySystemRoles {
        expiryTime = time;
        emit ExpiryTimeUpdated(msg.sender, time);
    }

    function getExpiryTime() external view returns (uint256) {
        return expiryTime;
    }

    /**
     * @dev Updates the grace period.
	 * @param time The new grace period in seconds.
	 */
    function setGracePeriod(uint256 time) external onlySystemRoles {
        gracePeriod = time;
        emit GracePeriodUpdated(msg.sender, time);
    }

    function setRegistryCost(uint256 _registryCost) external onlySystemRoles {
        registryCost = _registryCost;
    }

    function setRegistryRenewCost(uint256 _registryRenewCost) external onlySystemRoles {
        registryRenewCost = _registryRenewCost;
    }

    function getGracePeriod() external view returns (uint256) {
        return gracePeriod;
    }

    function _setPhoneRecord(
        bytes32 phoneHash,
        address owner,
        address resolver,
        string memory label
    ) internal onlyVerified(phoneHash) onlyVerifiedOwner(phoneHash) {
        require(msg.value >= convertAmountToETH(registryCost), 'fee must be greater than or equal to the registryCost fee');

        PhoneRecord storage recordData = records[phoneHash];
        require(!recordData.exists, 'phone record already exists');

        ResolverRecord storage resolverRecordData = resolverRecordMapping[label];

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;
        }
        recordData.phoneHash = phoneHash;
        recordData.owner = owner;
        recordData.createdAt = block.timestamp;
        recordData.exists = true;
        recordData.isInGracePeriod = false;
        recordData.isExpired = false;
        recordData.expirationTime = block.timestamp + expiryTime;
        recordData.wallet.push(resolverRecordData);

        (bool success,) = address(this).call{value : msg.value}('');

        require(success, 'Transfer failed.');

        if (msg.value > convertAmountToETH(registryCost)) {
            (bool sent,) = msg.sender.call{value : msg.value - convertAmountToETH(registryCost)}('');
            require(sent, 'Transfer failed.');
        }

        emit PhoneRecordCreated(phoneHash, resolver, owner);
    }

    function _linkphoneHashToWallet(
        bytes32 phoneHash,
        address resolver,
        string memory label
    ) internal {
        ResolverRecord storage resolverRecordData = resolverRecordMapping[label];
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.exists, 'phone record not found');
        require(!resolverRecordData.exists, 'resolver label already exist');

        if (!resolverRecordData.exists) {
            resolverRecordData.label = label;
            resolverRecordData.createdAt = block.timestamp;
            resolverRecordData.wallet = resolver;
            resolverRecordData.exists = true;

            recordData.wallet.push(resolverRecordData);
        }
    }

    /**
     * @dev Returns the hash for a given phoneHash
	 * @param phoneHash The phoneHash to hash
	 * @return The ENS node hash.
	 */
    function _hash(bytes32 phoneHash) internal pure returns (bytes32) {
        return keccak256(abi.encode(phoneHash));
    }

    /**
     * @dev Returns the address that owns the specified phone number phoneHash.
	 * @param phoneHash The specified phoneHash.
	 */
    function _getRecord(bytes32 phoneHash)
    internal
    view
    returns (
        address owner,
        ResolverRecord[] memory,
        bytes32,
        uint256 createdAt,
        bool exists,
        bool isInGracePeriod,
        bool isExpired,
        bool isVerified,
        uint256 expirationTime
    )
    {
        PhoneRecord storage recordData = records[phoneHash];
        require(recordData.exists, 'phone record not found');
        bool _isInGracePeriod = _hasPassedExpiryTime(phoneHash);
        bool _isExpired = _hasPassedGracePeriod(phoneHash);
        bool _isVerified = false;

        return (
        recordData.owner,
        recordData.wallet,
        recordData.phoneHash,
        recordData.createdAt,
        recordData.exists,
        _isInGracePeriod,
        _isExpired,
        _isVerified,
        recordData.expirationTime
        );
    }

    function convertAmountToETH(uint256 usdAmount) internal view returns (uint256) {
        uint256 ethPrice = uint256(getEtherPriceInUSD());
        uint256 ethAmount = ((usdAmount) / ethPrice) * 1 ether;
        return ethAmount;
    }

    /**
     * @dev Returns the latest price
	 */

    function getEtherPriceInUSD() internal view returns (int256) {
        (
        ,
        /*uint80 roundID*/
        int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
        ,
        ,

        ) = AggregatorV3Interface(priceFeed).latestRoundData();
        return price;
    }

    /**
     * @dev Returns the expiry state of an existing phone record.
	 * @param phoneHash The specified phoneHash.
	 */
    function _hasPassedExpiryTime(bytes32 phoneHash) internal view hasExpiryOf(phoneHash) returns (bool) {
        return block.timestamp > records[phoneHash].expirationTime;
    }

    /**
     * @dev Returns the grace period state of an existing phone record.
	 * @param phoneHash The specified phoneHash.
	 */
    function _hasPassedGracePeriod(bytes32 phoneHash) internal view hasExpiryOf(phoneHash) returns (bool) {
        return block.timestamp > (records[phoneHash].expirationTime + gracePeriod);
    }

    /**
     * @dev Withdraws funds from the protocol contract
        * @param amount The amount to withdraw
        * @param _recipient The recipient of the funds
        */
    function withdraw(address _recipient, uint256 amount) external onlySystemRoles {
        require(_recipient != address(0), 'recipient address cannot be zero address');
        require(amount > 0, 'amount must be greater than zero');
        (bool success,) = _recipient.call{value : amount}('');
        require(success, 'Transfer failed.');
    }

    //============MODIFIERS==============
    /**
     * @dev Permits modifications only by the owner of the specified phoneHash.
	 * @param phoneHash The phoneHash of the record owner to be compared.
	 */
    modifier authorised(bytes32 phoneHash) {
        address owner = records[phoneHash].owner;
        require(owner == msg.sender, 'caller is not authorised');
        _;
    }

    /**
     * @dev Permits the function to run only if expiry of record is found
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
    modifier hasExpiryOf(bytes32 phoneHash) {
        require(records[phoneHash].expirationTime > 0, 'phone expiry record not found');
        _;
    }

    /**
     * @dev Permits the function to run only if phone record is not expired.
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
    modifier expired(bytes32 phoneHash) {
        bool _hasExpired = _hasPassedExpiryTime(phoneHash);
        if (_hasExpired) {
            PhoneRecord storage recordData = records[phoneHash];
            recordData.isInGracePeriod = true;
            emit PhoneRecordEnteredGracePeriod(phoneHash);
        }
        _;
    }

    /**
     * @dev Permits the function to run only if phone record is still authenticated.
	 * @param phoneHash The phoneHash of the record to be compared.
	 */
    modifier authenticated(bytes32 phoneHash) {
        bool _hasExhaustedGracePeriod = _hasPassedGracePeriod(phoneHash);
        if (_hasExhaustedGracePeriod) {
            PhoneRecord storage recordData = records[phoneHash];
            recordData.isInGracePeriod = false;
            recordData.isExpired = true;
            emit PhoneRecordExpired(phoneHash);
            revert('phone record has expired, please renew');
        }
        _;
    }

    modifier onlyVerified(bytes32 phoneHash) {
        require(this.getVerificationRecord(phoneHash).isVerified, 'phone record is not verified');
        _;
    }
    modifier onlyVerifiedOwner(bytes32 phoneHash) virtual {
        require(this.getVerificationRecord(phoneHash).owner == msg.sender, 'caller is not verified owner');
        _;
    }
}
