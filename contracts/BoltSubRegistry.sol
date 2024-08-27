// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import "./interfaces/ISubRegistry.sol";
import "./interfaces/IBoltRegistry.sol";

contract BoltSubRegistry is AccessControlEnumerable, ISubRegistry {

    // Role for admin of the sub registry
    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");


    IBoltRegistry private _boltRegistry;

    /// Events
    event BoltRegistrySet(address registry);

    /// Custom errors
    error NotAuthorized();
    error WrongAddress();
    error ExtraDataRequired();

    /**
     * @dev Constructor that sets up roles and default sub-registry.
     * @param admin The address of the admin.
     * @param registry The address of the default sub-registry.
     */
    constructor(address admin, address registry) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(REGISTRY_ADMIN_ROLE, admin);
        _setBoltRegistry(registry);
    }

    /**
     * @dev Modifier to check if the caller has the admin role.
     */
    modifier onlyAdmin() {
        if (!hasRole(REGISTRY_ADMIN_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }


    /// Sub registry functions

    /// @dev extraData is requiered but handled by Bolt software, so URL string is empty
    function isExtraDataRequired() external view returns (bool, string memory) {
        return (true, "");
    }

    // @dev enforcing using method with extraData
    function isPreconferForSlot(bytes calldata validatorPubkey, uint64 slotNumber) external view returns (PreconferData memory) {
        revert ExtraDataRequired();
    }

    // @dev wrapper for Bolt registry
    function isPreconferForSlot(bytes calldata validatorPubkey, uint64 slotNumber, bytes calldata extraData) external view returns (PreconferData memory) {
        if (extraData.length == 0) {
            revert ExtraDataRequired();
        }

        (uint64 validatorIndex) = abi.decode(extraData, (uint64));

        IBoltRegistry.Registrant memory registrant = _boltRegistry.getOperatorForValidator(validatorIndex);
        if (registrant.status != IBoltRegistry.Status.ACTIVE) {
            revert NoValidPreconfer();
        }

        return PreconferData({
            preconferAddress: registrant.operator,
            slashableBalance: registrant.balance,
            gasLimit: 0,
            rpc: registrant.metadata.rpc
        });
    }


    /// Bolt registry functions

    /**
     * @dev Get the Bolt registry
     */
    function getBoltRegistry() external view returns (IBoltRegistry) {
        return _boltRegistry;
    }

    /**
     * @dev Set the Bolt registry
     */
    function setBoltRegistry(address registry) external onlyAdmin {
        _setBoltRegistry(registry);
    }

    /**
     * @dev Internal function to set the Bolt registry
     */
    function _setBoltRegistry(address registry) internal {
        if (registry == address(0)) {
            revert WrongAddress();
        }
        _boltRegistry = IBoltRegistry(registry);
        emit BoltRegistrySet(registry);
    }
}
