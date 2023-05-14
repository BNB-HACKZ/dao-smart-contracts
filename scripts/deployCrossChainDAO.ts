import { utils, constants, BigNumber, getDefaultProvider} from 'ethers';
import { ethers } from "hardhat";
//import { ethers } from "ethers";

import fs from "fs/promises";
import { CrossChainDAO, CrossChainDAO__factory, GovernanceToken, GovernanceToken__factory } from '../typechain-types';
import { parseEther } from "ethers/lib/utils";
import { isTestnet, wallet } from "../config/constants";

const {defaultAbiCoder} = utils;

const { deployUpgradable } = require("@axelar-network/axelar-gmp-sdk-solidity");
const {utils: {
  deployContract
}} = require("@axelar-network/axelar-local-dev");

let chains = isTestnet ? require("../config/testnet.json") : require("../config/local.json");

let GovernanceTokenAddr = "0x63C69067938eB808187c8cCdd12D5Bcf0375b2Ac";
const moonBeamDAOAddr = "0xA06AebAb1396ddBA55703341164BD5eeD2530A25"

//const spokeChainNames = ["Moonbeam", "Avalanche", "Ethereum", "Fantom", "Polygon"];

const spokeChainNames = ["Polygon", "Avalanche"];
const spokeChainIds:any = [];

const satellitedAddr: any = "";

function getChainIds(chains: any){
    for(let i = 0; i < spokeChainNames.length; i++) {
        let chainName  = spokeChainNames[i];
        //let chainInfo = chainsInfo[i];
        chains.find((chain: any) => {
            if(chain.name === chainName){
               spokeChainIds.push(chain.chainId); 
        }});    
    }
}

export async function main() {
     getChainIds(chains);
     await crossChainDAODeploy("Binance", wallet, GovernanceTokenAddr);
     //await interact("Moonbeam", wallet, moonBeamDAOAddr);
 
}

async function crossChainDAODeploy(hubChain: string, wallet: any, governanceToken: any) {
    const chain = chains.find((chain: any) => chain.name === hubChain);

    console.log(`Deploying CrossChainDAO for ${chain.name}.`);
    const provider = getDefaultProvider(chain.rpc);
    const connectedWallet = wallet.connect(provider);

    const crossChainDAOFactory = new CrossChainDAO__factory(connectedWallet);
    const contract: CrossChainDAO = await crossChainDAOFactory.deploy(
        governanceToken,
        chain.gateway,
        chain.gasReceiver,
        spokeChainIds,
        spokeChainNames
    );
    const deployTxReceipt = await contract.deployTransaction.wait();
    console.log(`Cross chain DAO has been deployed at ${contract.address}`);
}

async function interact(hubChain: string, wallet: any, daoAddr: string) {
    const chain = chains.find((chain: any) => chain.name === hubChain);
    const provider = getDefaultProvider(chain.rpc);
    const connectedWallet = wallet.connect(provider);

    const crossChainDAOFactory =  new CrossChainDAO__factory(connectedWallet);
    const crossChainDAOInstance = crossChainDAOFactory.attach(daoAddr);

    const result = await crossChainDAOInstance.gasService();
    //const result2 = await governanceTokenInstance.spokeChainNames(0);
    console.log(result);
   
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

  