import { utils, constants, BigNumber, getDefaultProvider} from 'ethers';
import { ethers } from "ethers";

import fs from "fs/promises";
import { CrossChainDAO, CrossChainDAO__factory, GovernanceToken, GovernanceToken__factory, SimpleIncrementer__factory } from '../typechain-types';
import { parseEther } from "ethers/lib/utils";
import { isTestnet, wallet } from "../config/constants";

const {defaultAbiCoder} = utils;



let chains = isTestnet ? require("../config/testnet.json") : require("../config/local.json");

let GovernanceTokenAddr = "0x63C69067938eB808187c8cCdd12D5Bcf0375b2Ac";
const moonBeamDAOAddr = "0x1dDabA87ec15241eEAC057FBC37C5F00CeBCEd34"

//const spokeChainNames = ["Moonbeam", "Avalanche", "Ethereum", "Fantom", "Polygon"];

const spokeChainNames = ["Moonbeam", "Avalanche"];
const spokeChainIds:any = [];ethers

let hubChain = 'Moonbeam'

const chain = chains.find((chain: any) => chain.name === hubChain);
const provider = getDefaultProvider(chain.rpc);
const connectedWallet = wallet.connect(provider);





export async function main() {
    await executeProposal('Take the whole site!');
   
 
}



async function executeProposal(description: string) {

    
    const crossChainDAOFactory =  new CrossChainDAO__factory(connectedWallet);
    const crossChainDAOInstance = crossChainDAOFactory.attach(moonBeamDAOAddr);
    
    const incrementerFactory = new SimpleIncrementer__factory(connectedWallet);
    console.log('Deploying Incrementer....')
   const incrementerContract = await incrementerFactory.deploy();
   console.log('deployed!')
    const incrementer = incrementerFactory.attach(incrementerContract.address)

    const incrementData = incrementerContract.interface.encodeFunctionData("increment", )

    const targets = [incrementerContract.address];
    const values = [0];
    const callDatas = [incrementData];
    let descHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(description));

    console.log('Executing Proposal...')

    const result = await (await crossChainDAOInstance.crossChainPropose(targets, values, callDatas, descHash, { value: "10000000000000000" })).wait();

    

    console.log(' Proposal Executed!');




   
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

  