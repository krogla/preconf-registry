// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import "./interfaces/ISubRegistry.sol";
import "./interfaces/ILidoNOR.sol";

/**
 * @title LidoNORSubRegistry
 * @dev A prototype of sub-registry wrapper contract for the Lido NO registry.
 */

contract LidoNORSubRegistry is AccessControlEnumerable, ISubRegistry {
    // Role for admin of the sub registry
    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    ILidoNOR private _nor;
    string private _extraDataUrl;

    /// @dev example mapping for NO's RPCs
    mapping(address => string) private _noRpcs;

    /// Events
    event NORSet(address registry);

    /// Custom errors
    error NotAuthorized();
    error WrongAddress();
    error ExtraDataRequired();

    /**
     * @dev Constructor that sets up roles and default sub-registry.
     * @param admin The address of the admin.
     * @param registry The address of the default sub-registry.
     */
    constructor(address admin, address nor, string memory extraDataUrl) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(REGISTRY_ADMIN_ROLE, admin);
        _setNOR(nor);
        _extraDataUrl = extraDataUrl;
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
        return (true, _extraDataUrl);
    }

    // @dev enforcing using method with extraData
    function isPreconferForSlot(bytes calldata validatorPubkey, uint64 slotNumber)
        external
        view
        returns (PreconferData memory)
    {
        revert ExtraDataRequired();
    }

    // @dev wrapper for Lido NO registry
    function isPreconferForSlot(bytes calldata validatorPubkey, uint64 slotNumber, bytes calldata extraData)
        external
        view
        returns (PreconferData memory)
    {
        if (extraData.length == 0) {
            revert ExtraDataRequired();
        }

        (uint256 noId, uint256 keyIdx) = abi.decode(extraData, (uint256, uint256));

        (bool active,, address rewardAddress,,,,) = _nor.getNodeOperator(noId, false);
        if (!active) {
            revert NoValidPreconfer();
        }

        (bytes memory key,, bool used) = _nor.getSigningKey(noId, keyIdx);
        if (!used || key.length != validatorPubkey.length || keccak256(key) != keccak256(validatorPubkey)) {
            revert NoValidPreconfer();
        }

        return PreconferData({
            preconferAddress: rewardAddress,
            slashableBalance: _calculateSlashableBalance(noId),
            gasLimit: 0,
            rpc: _getRpc(rewardAddress)
        });
    }

    /// Lido NOR functions

    /// @dev Dummy function to get the NO RPC
    function _getRpc(address rewardAddress) internal view returns (string memory) {
        return _noRpcs[rewardAddress];
    }

    /// @dev Dummy function to calculate the slashable balance
    function _calculateSlashableBalance(uint256 noId) internal view returns (uint256) {
        // TODO: implement real calculation
        return 123456;
    }

    /**
     * @dev Set the Bolt registry
     */
    function setAPIURL(string memory url) external onlyAdmin {
        _extraDataUrl = url;
    }

    /**
     * @dev Get the Bolt registry
     */
    function getNOR() external view returns (INOR) {
        return _nor;
    }

    /**
     * @dev Set the Bolt registry
     */
    function setNOR(address registry) external onlyAdmin {
        _setNOR(registry);
    }

    /**
     * @dev Internal function to set the Bolt registry
     */
    function _setNOR(address registry) internal {
        if (registry == address(0)) {
            revert WrongAddress();
        }
        _nor = INOR(registry);
        emit NORSet(registry);
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns (bool) {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b) internal pure returns (bool) {
        return memcmp(bytes(a), bytes(b));
    }
}
