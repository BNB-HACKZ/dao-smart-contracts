import { utils, constants, BigNumber, getDefaultProvider } from 'ethers';
import { ethers } from "hardhat";
//import { ethers } from "ethers";

import fs from "fs/promises";
import { CampaignManager, CampaignManager__factory } from '../typechain-types';
import { parseEther } from "ethers/lib/utils";
import { isTestnet, wallet } from "../config/constants";

const { defaultAbiCoder } = utils;

const { deployUpgradable } = require("@axelar-network/axelar-gmp-sdk-solidity");
const { utils: {
    deployContract
} } = require("@axelar-network/axelar-local-dev");

let chains = isTestnet ? require("../config/testnet.json") : require("../config/local.json");


const BinanceDAOAddr = "0x558388D8Ebcf227D6cF1C1b8345754259800CA3F"

//const spokeChainNames = ["Moonbeam", "Avalanche", "Ethereum", "Fantom", "Polygon"];

const spokeChainNames = ["Polygon", "Avalanche"];
const spokeChainIds: any = [];

const HubChain = "Binance";
const campaignManagerAddr: any = "0xe8d3a73f6351f9f5dd6A577aD4ddF7d5C84DF5C8";

let encodedSpokeChainIds: any;
let encodedSpokeChainNames: any;

function getChainIds(chains: any) {
    for (let i = 0; i < spokeChainNames.length; i++) {
        let chainName = spokeChainNames[i];
        //let chainInfo = chainsInfo[i];
        chains.find((chain: any) => {
            if (chain.name === chainName) {
                spokeChainIds.push(chain.chainId);

            }
        });
    }
}


export async function main() {
    getChainIds(chains);
    console.log(spokeChainIds)
    encodedSpokeChainIds = ethers.utils.defaultAbiCoder.encode(
        ["uint32[]"],
        [spokeChainIds]
    );
    encodedSpokeChainNames = ethers.utils.defaultAbiCoder.encode(
        ["string[]"],
        [spokeChainNames]
    );

    await campiagnSatelliteDeploy(HubChain, wallet);
    //await interact(HubChain, wallet, BinanceDAOAddr);


}

async function campiagnSatelliteDeploy(hubChain: any, wallet: any) {
    const chain = chains.find((chain: any) => chain.name === hubChain);

    console.log(`Deploying Campaign manager for ${chain.name}.`);
    const provider = getDefaultProvider(chain.rpc);
    const connectedWallet = wallet.connect(provider);

    const campaignManagerFactory = new CampaignManager__factory(connectedWallet);
    const contract: CampaignManager = await campaignManagerFactory.deploy(
        chain.gateway,
        chain.gasReceiver,
        encodedSpokeChainIds,
        encodedSpokeChainNames
    );
    const deployTxReceipt = await contract.deployTransaction.wait();
    console.log(`Cross Campaign Manager has been deployed at ${contract.address}`);
}

async function interact(hubChain: string, wallet: any, daoAddr: string) {
    const chain = chains.find((chain: any) => chain.name === hubChain);
    const provider = getDefaultProvider(chain.rpc);
    const connectedWallet = wallet.connect(provider);

    const campaignManagerFactory = new CampaignManager__factory(connectedWallet);
    const campaignManagerInstance = campaignManagerFactory.attach(campaignManagerAddr);

    const result = await campaignManagerInstance.spokeChainNames(1);

    console.log(result);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

