// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RootRegistry is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// Roles

    // Role for admin of the root registry
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Mapping of withdrawal credential to a set of sub-registry contract addresses
    mapping(bytes32 => EnumerableSet.AddressSet) private _subRegistries;

    // Default sub-registry for the whole root registry
    address private _defaultSubRegistry;

    /// Events
    event SubRegistryAdded(bytes32 indexed withdrawalCredential, address indexed registry);
    event SubRegistryRemoved(bytes32 indexed withdrawalCredential, address indexed registry);
    event DefaultSubRegistrySet(address registry);

    /// Custom errors
    error NotAuthorized();
    error SubRegistryAlreadyExists();
    error SubRegistryDoesNotExist();
    error WrongAddress();

    /**
     * @dev Constructor that sets up roles and default sub-registry.
     * @param admin The address of the admin.
     * @param registry The address of the default sub-registry.
     */
    constructor(address admin, address registry) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, admin);
        _setDefaultSubRegistry(registry);
    }

    /**
     * @dev Modifier to check if the caller has the admin role.
     */
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    /**
     * @dev Adds a sub-registry.
     * @param withdrawalCredential The withdrawal credential associated with the sub-registry.
     * @param registry The address of the sub-registry to add.
     */
    function addSubRegistry(bytes32 withdrawalCredential, address registry) external onlyAdmin {
        if (!_subRegistries[withdrawalCredential].add(registry)) {
            revert SubRegistryAlreadyExists();
        }

        emit SubRegistryAdded(withdrawalCredential, registry);
    }

    /**
     * @dev Removes a sub-registry.
     * @param withdrawalCredential The withdrawal credential associated with the sub-registry.
     * @param registry The address of the sub-registry to remove.
     */
    function removeSubRegistry(bytes32 withdrawalCredential, address registry) external onlyAdmin {
        if (!_subRegistries[withdrawalCredential].remove(registry)) {
            revert SubRegistryDoesNotExist();
        }

        emit SubRegistryRemoved(withdrawalCredential, registry);
    }

    /**
     * @dev Gets the sub-registries associated with a withdrawal credential.
     * @param withdrawalCredential The withdrawal credential to query.
     * @return An array of addresses of the sub-registries.
     */
    function getSubRegistries(bytes32 withdrawalCredential) external view returns (address[] memory) {
        address[] memory registries = _subRegistries[withdrawalCredential].values();

        if (registries.length == 0) {
            registries = new address[](1);
            registries[0] = _defaultSubRegistry;
        }

        return registries;
    }

    /**
     * @dev Gets the count of sub-registries associated with a withdrawal credential.
     * @param withdrawalCredential The withdrawal credential to query.
     * @return The number of sub-registries.
     */
    function getSubRegistriesCount(bytes32 withdrawalCredential) external view returns (uint256) {
        return _subRegistries[withdrawalCredential].length();
    }


    /// Default sub-registry functions

    /**
     * @dev Get the default sub-registry for the root registry
     */
    function getDefaultSubRegistry() external view returns (address) {
        return _defaultSubRegistry;
    }

    /**
     * @dev Set the default sub-registry for the root registry
     */
    function setDefaultSubRegistry(address registry) external onlyAdmin {
        _setDefaultSubRegistry(registry);
    }

    /**
     * @dev Internal function to set the default sub-registry for the root registry
     */
    function _setDefaultSubRegistry(address registry) internal {
        if (registry == address(0)) {
            revert WrongAddress();
        }
        _defaultSubRegistry = registry;
        emit DefaultSubRegistrySet(registry);
    }
}
