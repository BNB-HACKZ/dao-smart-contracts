// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {StringToAddress, AddressToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";
import {StringToBytes32, Bytes32ToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol";

import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract DAOSatellite is AxelarExecutable {
    // The cross-chain DAO is never deployed on the spoke chains because it wouldn't be efficient to replicate all
    // of the data across each spoke chain. But, we still need an interface to work with the CrossChainDAO smart contract
    // on the spoke chains. Hence, we will create a satellite contract named DAOSatellite.

    IAxelarGasService public immutable gasService;

    using StringToAddress for string;
    using AddressToString for address;

    string public hubChain;
    IVotes public immutable token;
    uint256 public immutable targetSecondsPerBlock;

    mapping(uint256 => RemoteProposal) public proposals;
    mapping(uint256 => ProposalVote) public proposalVotes;

    struct ProposalVote {
        uint256 proposalVote;
        uint256 forVotes;
        uint256 abstainVotes;
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct RemoteProposal {
        //Blocks provided by the hub chain as to when the local values should start/finish
        uint256 localVoteStart;
        bool voteFinished;
    }

    constructor(
        string memory _hubChain,
        address _gateway,
        address _gasService,
        IVotes _token,
        uint _targetSecondsPerBlock
    ) payable AxelarExecutable(_gateway) {
        gasService = IAxelarGasService(_gasService);
        hubChain = _hubChain;
        token = _token;
        targetSecondsPerBlock = _targetSecondsPerBlock; // predetermined seconds-per-block estimate
    }

    //checks whether a proposal exists in the contract by checking if the localVoteStart variable of the corresponding
    //proposal in the proposals mapping has been set to a non-zero value.
    function isProposal(uint256 proposalId) public view returns (bool) {
        return proposals[proposalId].localVoteStart != 0;
    }

    //This smart contract communicates with the CrossChainDAO smart contract, and recall that there are currently
    //two instances in which the CrossChainDAO sends a message:
    //When the CrossChainDAO wants to notify the spoke chains of a new proposal (function selector is 0)
    //When the CrossChainDAO wants the spoke chains to send their voting data to the hub chain (function selector is 1)

    function _execute(
        string calldata sourceChain,
        string calldata /*sourceAddress*/,
        bytes memory _payload
    ) internal override /*(AxelarExecutable)*/ {
        require(
            keccak256(abi.encodePacked(sourceChain)) ==
                keccak256(abi.encodePacked(hubChain)),
            "Only messages from the hub chain can be received!"
        );

        uint16 option;
        assembly {
            option := mload(add(_payload, 32))
        }

        if (option == 0) {
            //Begin proposal on the chain, with local block times
            //To do this, decode the payload, which includes a proposal ID and the timestamp of when the proposal was made as mentioned in the CrossChainDAO section
            //Perform some calculations to generate a cutOffBlockEstimation by subtracting blocks from the current block based on
            //the timestamp and a predetermined seconds-per-block estimate
            // Add a RemoteProposal struct to the proposals map, effectively registering the proposal and its voting-related data on the spoke chain

            (, uint256 proposalId, uint256 proposalStart) = abi.decode(
                _payload,
                (uint16, uint256, uint256)
            );
            require(
                !isProposal(proposalId),
                "Proposal ID must be unique, and not already set"
            );

            uint256 cutOffBlockEstimation = 0;
            if (proposalStart < block.timestamp) {
                uint256 blockAdjustment = (block.timestamp - proposalStart) /
                    targetSecondsPerBlock;
                if (blockAdjustment < block.number) {
                    cutOffBlockEstimation = block.number - blockAdjustment;
                } else {
                    cutOffBlockEstimation = block.number;
                }
            }
        } else if (option == 1) {
            //send vote results back to the hub chain
        }
    }
}
