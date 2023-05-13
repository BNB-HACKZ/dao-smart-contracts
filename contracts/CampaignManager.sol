//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Campaign.sol";

contract CampaignManager {
    uint256 public campaignIdCounter;
    Campaign[] campaigns;
    mapping(address => uint256) public campaignIds;
    uint16[] public spokeChains;
    string[] public spokeChainNames;

    function createCampaign(
        string memory _campaignCID,
        uint256 _target,
        uint16[] memory _spokeChains, string[] memory _spokeChainNames
    ) public returns (bool) {
        uint256 campaignID = campaignIdCounter;
        campaignIdCounter++;
        Campaign campaign = new Campaign(
            msg.sender,
            _campaignCID,
            block.timestamp,
            _target,
            campaignID
        );
        campaigns.push(campaign);
        campaignIds[address(campaign)] = campaignID;
        return true;
    }

    function getAllCampaignAddresses()
        public
        view
        returns (address[] memory _campaigns)
    {
        _campaigns = new address[](campaignIdCounter);
        for (uint i = 0; i < campaignIdCounter; i++) {
            _campaigns[i] = address(campaigns[i]);
        }
        return _campaigns;
    }

    function getCampaignDetails(
        address[] calldata _campaignList
    )
        public
        view
        returns (
            string[] memory campaignCID,
            address[] memory owner,
            uint256[] memory id,
            uint256[] memory raisedFunds
        )
    {
        owner = new address[](_campaignList.length);
        id = new uint256[](_campaignList.length);
        campaignCID = new string[](_campaignList.length);
        raisedFunds = new uint256[](_campaignList.length);

        for (uint256 i = 0; i < _campaignList.length; i++) {
            uint256 campaignID = campaignIds[_campaignList[i]];
            owner[i] = campaigns[campaignID].owner();
            id[i] = campaigns[campaignID].id();
            campaignCID[i] = campaigns[campaignID].campaignCID();
            raisedFunds[i] = campaigns[campaignID].raisedFunds();
        }

        return (campaignCID, owner, id, raisedFunds);
    }
}
