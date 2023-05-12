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
const moonBeamDAOAddr = "0x3a6530214288EBCc1B958Fe3C4BCc8a026B4EA0b"

//const spokeChainNames = ["Moonbeam", "Avalanche", "Ethereum", "Fantom", "Polygon"];

const spokeChainNames = ["Moonbeam", "Avalanche"];
const spokeChainIds:any = [];

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
     //await crossChainDAODeploy("Moonbeam", wallet, GovernanceTokenAddr);
     await interact("Moonbeam", wallet, moonBeamDAOAddr);
 
}

async function crossChainDAODeploy(hubChain: string, wallet: any, governanceToken: any) {
    const chain = chains.find((chain: any) => chain.name === hubChain);

    console.log(`Deploying CrossChainDAO for ${chain.name}.`);
    const provider = getDefaultProvider(chain.rpc);
    const connectedWallet = wallet.connect(provider);

    // const GovernanceTokenfactory =  new GovernanceToken__factory(connectedWallet);
    // const governanceTokenInstance = GovernanceTokenfactory.attach(token)

    const crossChainDAOFactory = new CrossChainDAO__factory(connectedWallet);
    const contract: CrossChainDAO = await crossChainDAOFactory.deploy(
        governanceToken,
        chain.gateway,
        chain.gasService,
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

    const GovernanceTokenfactory =  new CrossChainDAO__factory(connectedWallet);
    const governanceTokenInstance = GovernanceTokenfactory.attach(daoAddr);

    const result = await governanceTokenInstance.gasService();
    console.log(result);
   
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

  