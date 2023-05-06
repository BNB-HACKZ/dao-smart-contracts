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

  constructor(IVotes _token, address _gateway, address _gasService, uint16[] memory _spokeChains)
        Governor("CrossChainDAO")
        GovernorSettings(0 /* 0 block */, 30 /* 6 minutes */, 0)
        GovernorVotes(_token)
        AxelarExecutable(_gateway)
        CrossChainGovernorCountingSimple(_spokeChains)  
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
    function _execute (
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata _payload
    ) internal override {
        string memory message = abi.decode(_payload, (string));
    }

}


