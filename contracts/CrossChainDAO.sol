// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


import { IAxelarGasService } from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
//import { IInterchainTokenLinker } from "./token-linker/contracts/interfaces/IInterchainTokenLinker.sol";
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { StringToAddress, AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";


import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
//import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "./CrossChainGovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

contract CrossChainDAO is Governor, GovernorSettings, CrossChainGovernorCountingSimple, GovernorVotes, AxelarExecutable {
// Count votes from spoke chains
// Add a new collection phase between voting and execution
// Requesting the collection of votes from spoke chains
// Receiving the collection of votes from spoke chains
// Add functionality to let spoke chains know when there is a new proposal to vote on
// (Optional) Add ability to receive cross-chain messages to do non-voting action(s), like proposing or executing

//The logic and data will be housed in a parent contract of the CrossChainDAO

//The GovernorCountingSimple contract defines how votes are counted and what votes are. It stores how many votes
// have been cast per proposal, what a vote can be (for, against, abstain), and it also controls whether or not 
// quorum has been reached.

//The only difference between our cross-chain variant and the single-chain variant is that the cross-chain variant
// must account for the collection phase and the votes that come with it
    IAxelarGasService public immutable gasService;

    using StringToAddress for string;
    using AddressToString for address;

// Whether or not the DAO finished the collection phase. It would be more efficient to add Collection as a status
// in the Governor interface, but that would require editing the source file. It is a bit out of scope to completely
// refactor the OpenZeppelin governance contract for cross-chain action!
    mapping(uint256 => bool) public collectionFinished;
    mapping(uint256 => bool) public collectionStarted;
 
    constructor(IVotes _token, address _gateway, address _gasService, uint16[] memory _spokeChains, string[] memory _spokeChainNames)
        Governor("CrossChainDAO")
        GovernorSettings(0 /* 0 block */, 30 /* 6 minutes */, 0)
        GovernorVotes(_token)
        AxelarExecutable(_gateway)
        CrossChainGovernorCountingSimple(_spokeChains, _spokeChainNames)  
    {
        gasService = IAxelarGasService(_gasService);
    }
  
    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 1e18;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    
    //Implementing a Collection Phase
//a new collection phase should be added in between the voting period and the proposal's execution. 
//During this phase:
//Execution must be postponed (execution must be disabled)
//The hub chain must request voting data from the spoke chains
//The spoke chain must subsequently send the voting data


// function that checks whether or not that each of the spoke chains have sent in voting data before
// a proposal is executed (which is found by checking initialized on a proposal on all chains)
    function _beforeExecute(
        uint256 _proposalId,
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        bytes32 _descriptionHash
    ) internal override {
        finishCollectionPhase(_proposalId);

        require(
            collectionFinished[_proposalId],
            "Collection phase for this proposal is unfinished!"
        );

        super._beforeExecute(_proposalId, _targets, _values, _calldatas, _descriptionHash);

    }

    //function that marks a collection phase as true if all of the spoke chains have 
    //sent a cross-chain message back

    function finishCollectionPhase(uint256 _proposalId) public {
        bool phaseFinished = true;
        //loop will only run as long as phaseFinished == true
        for(uint16 i = 0; i < spokeChains.length && phaseFinished; i++) {
            phaseFinished = phaseFinished && proposalIdToChainIdToSpokeVotes[_proposalId][spokeChains[i]].initialized;
        }

        collectionFinished[_proposalId] = phaseFinished; //this sets the collection of the proposalId on all chains as finished
    }

    // If you wanted, you could also add the collection phase within the IGovernor state machine. This would require more effort 
    // than it would be worth and is more feasible for a cross-chain DAO written from scratch

  
    // We can start by making a new public trustless function to begin the collection phase, similar to the execute function:
    // Requests the voting data from all of the spoke chains
    
//This function allows any user to start the collection process for a specific proposalId as long as:
//The voting phase for the proposal has finished
//The collection phase has not yet started
//Recall that each spoke chain will have a DAOSatellite smart contract associated with it that can also receive and send 
//cross-chain messages. This function sends a cross-chain message to every registered spoke chain's DAOSatellite during 
//the collection phase. The message contains a function selector, 1, and a proposal ID. The function selector is used to 
//request voting data for the given proposal instead of some other action from the destination DAOSatellite contract.

    function requestCollections(uint256 _proposalId) public payable {
        require(
            block.number > proposalDeadline(_proposalId),
            "Cannot request for vote collection until after the vote period is over!"
        );
        require(
            !collectionStarted[_proposalId],
            "Collection phase for this proposal has already started"
        );

        collectionStarted[_proposalId] = true;

        //sends an empty message to each of the aggregators. If they receive a
        // message at all, it is their cue to send data back

        for(uint16 i = 0; i < spokeChains.length; i++) {
             uint256 crossChainFee = msg.value / spokeChains.length;
            // using "1" as the function selector
            bytes memory payload = abi.encode(1, abi.encode(_proposalId));
            gasService.payNativeGasForContractCall{value: crossChainFee}(
            address(this), //sender
            spokeChainIdToChainName[spokeChains[i]], //destination chain
            address(this).toString(), //destination contract address, would be same address with address this since we using constant deployer
            payload,
            msg.sender //refund address
            );

              gateway.callContract(spokeChainIdToChainName[spokeChains[i]], address(this).toString(), payload);
        }
       

    } 
   
     function sendMessage(
        string calldata _destinationChain,
        string calldata _destinationAddress,
        string calldata _message
    ) external payable  {
        bytes memory payload = abi.encode(_message);
        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            _destinationChain,
            _destinationAddress, 
            payload,
            msg.sender
        );

        gateway.callContract(_destinationChain, _destinationAddress, payload);

    }

    //This function will receive cross chain voting data, will come back to implement it
    // function _execute (
    //     string calldata sourceChain,
    //     string calldata sourceAddress,
    //     bytes calldata _payload
    // ) internal override {
    //     string memory message = abi.decode(_payload, (string));
    // }

}


