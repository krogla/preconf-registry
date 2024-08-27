// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILidoNOR {
    function getNodeOperator(uint256 _nodeOperatorId, bool _fullInfo)
        external
        view
        returns (
            bool active,
            string memory name,
            address rewardAddress,
            uint64 totalVettedValidators,
            uint64 totalExitedValidators,
            uint64 totalAddedValidators,
            uint64 totalDepositedValidators
        );
    function getSigningKey(uint256 _nodeOperatorId, uint256 _index)
        external
        view
        returns (bytes memory key, bytes memory depositSignature, bool used);
}
