// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISubRegistry {

    struct PreconferData {
        address preconferAddress; // hot key pair for preconf signing
        uint256 slashableBalance; // amount of capital at risk
        uint64 gasLimit; // maximum block space for preconf
        string rpc; // url of rpc
    }

    error NoValidPreconfer();

    function isExtraDataRequired() external view returns (bool, string memory);

    function isPreconferForSlot(bytes calldata validatorPubkey, uint64 slotNumber) external view returns (PreconferData memory);

    // Perform preconfirmation for a given validator and slot, with the option to include additional `extraData`.
	function isPreconferForSlot(bytes calldata validatorPubkey, uint64 slotNumber, bytes calldata extraData ) external view returns (PreconferData memory);


//     function challengeProposer(
//         address _preconfer, SignedCommitment calldata _commitment
//     ) external payable;

//     function resolveChallenge(bytes32[] calldata _inclusionProof) external;
}
