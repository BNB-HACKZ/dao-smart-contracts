import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-gas-reporter';
import 'solidity-coverage';

const config: HardhatUserConfig = {
  // solidity: "0.8.0",
  solidity: {
    version: '0.8.9',
    settings: {
      evmVersion: process.env.EVM_VERSION || 'london',
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          peephole: true,
          inliner: true,
          jumpdestRemover: true,
          orderLiterals: true,
          deduplicate: true,
          cse: true,
          constantOptimizer: true,
          yul: true,
          yulDetails: {
            stackAllocation: true,
          },
        },
      },
    },
  },
};

export default config;
