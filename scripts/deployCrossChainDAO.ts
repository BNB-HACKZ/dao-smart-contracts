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

let GovernanceTokenAddr = "0x63092CB8640C8F3B221871bc0E21b7364799097D";
const moonBeamDAOAddr = "0xA06AebAb1396ddBA55703341164BD5eeD2530A25"

//const spokeChainNames = ["Moonbeam", "Avalanche", "Ethereum", "Fantom", "Polygon"];

const spokeChainNames = [ "Avalanche", "Polygon"];
const spokeChainIds:any = [];

const HubChain = "Binance";
//const satellitedAddr: any = "";

let encodedSpokeChainIds: any;
let encodedSpokeChainNames: any;

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
     encodedSpokeChainIds = ethers.utils.defaultAbiCoder.encode(
        ["uint16[]"],
        [spokeChainIds]
      );
     encodedSpokeChainNames = ethers.utils.defaultAbiCoder.encode(
        ["string[]"],
        [spokeChainNames]
      );

    await crossChainDAODeploy(HubChain, wallet, GovernanceTokenAddr);
    //await interact("Moonbeam", wallet, moonBeamDAOAddr);
 
 
}

async function crossChainDAODeploy(hubChain: any, wallet: any, governanceToken: string) {
    const chain = chains.find((chain: any) => chain.name === hubChain);

    console.log(`Deploying CrossChainDAO for ${chain.name}.`);
    const provider = getDefaultProvider(chain.rpc);
    const connectedWallet = wallet.connect(provider);

    // console.log( governanceToken,
    //     chain.gateway,
    //     chain.gasService,
    //     encodedSpokeChainIds,
    //     encodedSpokeChainNames)

    const crossChainDAOFactory = new CrossChainDAO__factory(connectedWallet);
    const contract: CrossChainDAO = await crossChainDAOFactory.deploy(
        governanceToken,
        chain.gateway,
        chain.gasReceiver,
        encodedSpokeChainIds,
        encodedSpokeChainNames
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

    const result = await crossChainDAOInstance.spokeChainNames(1);
    //const result2 = await governanceTokenInstance.spokeChainNames(0);
    console.log(result);
   
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

  