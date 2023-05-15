
import { isTestnet, wallet } from "../config/constants";
import { getDefaultProvider} from 'ethers';
import { DaoSatelite__factory } from '../typechain-types'; //TODO:

let chains = isTestnet ? require("../config/testnet.json") : require("../config/local.json");

const DAOSatelliteAddress:string = "" 
let sateliteChain = 'Moonbeam'

const chain = chains.find((chain: any) => chain.name === sateliteChain);
const provider = getDefaultProvider(chain.rpc);
const connectedWallet = wallet.connect(provider);


module.exports = async function (taskArgs,hre) {
    const { proposalid, support } = taskArgs;

    const DAOSatellite =  new DaoSatelite__factory(connectedWallet);
    const dao = DAOSatellite.attach(DAOSatelliteAddress);

    // Delegate votes to task args
    let tx = await (await dao.castVote(proposalid, support)).wait()
    console.log(`✅ [${chain.name}] DAOSatellite.castVote(${proposalid}, ${support})`)
    console.log(`...tx: ${tx.transactionHash}`);

}