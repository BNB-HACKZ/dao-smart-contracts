// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {StringToAddress, AddressToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";
import {StringToBytes32, Bytes32ToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol";
import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";

contract CampaignSatellite is AxelarExecutable, Upgradable {
   
    IAxelarGasService public immutable gasService;

    using StringToAddress for string;
    using AddressToString for address;

    error AlreadyInitialized();

    string public chainName; 

    string public hubChain;

    //mapping(uint256 => RemoteCampaign) public rcampaigns;
    mapping(uint256 => CampaignData) public campaigns;


    struct CampaignData {
        string campaignCID;
        address campaignOwner;
        uint256 campaignId;
        uint256 raisedFunds;
        bool hasReachedTarget;
        address[] donators;
    }

    enum CampaignStatus {
        Finished,
        Ongoing
    }

    // struct RemoteCampaign {
    //     //Blocks provided by the hub chain as to when the local values should start/finish
    //     uint256 localCampaignStart;
    //     bool campaignFinished;
    // }

    constructor(
        string memory _hubChain,
        address _gateway,
        address _gasService  
    ) payable AxelarExecutable(_gateway) {
        gasService = IAxelarGasService(_gasService);
        hubChain = _hubChain;
    }

    //checks whether a campaign exists in the contract by checking if the localVoteStart variable of the corresponding
    //campaign in the campaigns mapping has been set to a non-zero value.
    function isCampaign(uint256 campaignId) public view returns(bool) {

    }

    function _execute() internal {

    }

    function crossChainDonate() public virtual {

    }

    function countDonations() internal virtual {
        
    }


     function _setup(bytes calldata params) internal override {
        string memory chainName_ = abi.decode(params, (string));
        if (bytes(chainName).length != 0) revert AlreadyInitialized();
        chainName = chainName_;
    }

    function contractId() external pure returns (bytes32) {
        return keccak256("example");
    }

}