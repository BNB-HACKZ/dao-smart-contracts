//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract CampaignCountingSimple {

    enum CampaignStatus {
        Finished,
        Ongoing
    }

    // The spokechain IDs that the Campaign manager expects to receive data from during the 
    // collection phase
    uint16[] public spokeChains;
    string[] public spokeChainNames;

    constructor(uint16[] memory _spokeChains, string[] memory _spokeChainNames) {
        spokeChains = _spokeChains;
        spokeChainNames = _spokeChainNames;
        setSpokeChainData(_spokeChains, _spokeChainNames);
    }

    struct spokeChainData {
        uint16 spokeChainId;
        string spokeChainName;
    }

    struct SpokeCampaignData {
        //string campaignCID;
        address campaignOwner;
        uint256 campaignId;
        uint256 raisedFunds;
        bool hasReachedTarget;  //This checks whether data was received from the spoke chains or not
        address[] donators;
        bool initialized;
    }

    struct CampaignData {
        //string campaignCID;
        address campaignOwner;
        uint256 campaignId;
        uint256 raisedFunds;
        bool hasReachedTarget;
        address[] donators;
    }
    
    mapping(string => uint16) public spokeChainNameToSpokeChainId;

    // Maps a proposal ID to a map of a chain ID to summarized spoke voting data
    mapping(uint256 => mapping(uint16 => SpokeCampaignData)) public campaignIdToChainIdToSpokeCampaignData;
    // ...
    
    mapping(uint256 => CampaignData) private _campaignData;

    // struct SpokeDonationDetails {
    //     uint256 forVotes;
    //     uint256 againstVotes;
    //     uint256 abstainVotes;
    //     bool initialized; //This checks whether data was received from the spoke chains or not
    // }

     function setSpokeChainData(uint16[] memory _spokeChains, string[] memory _spokeChainNames) internal {
        require(_spokeChains.length == _spokeChainNames.length, "not equal lengths");
        for(uint16 i = 0; i < _spokeChains.length; i++) {
            spokeChainNameToSpokeChainId[_spokeChainNames[i]] = _spokeChains[i];
        }
    }

    function _targetReached() internal view virtual {

    }

    function _countDonations() internal virtual  {

    }




}
