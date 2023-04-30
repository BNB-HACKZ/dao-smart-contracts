// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {IInterchainTokenLinker} from "./token-linker/contracts/interfaces/IInterchainTokenLinker.sol";


//you can extend the ERC20Votes contract with the InterchainToken contract //try this later, for now I am using the interface
//to allow seamless interchain transfers and implement interchain vote methods using GMP

//extend erc20votes, and add new interchain vote methods using gmp and test it out. 
//Once that works, you can inherit from InterchainToken to benefit from native interchain transfers too

contract Token is ERC20Votes{
    bytes32 public tokenId;
    IAxelarGasService public immutable gasService;
    IAxelarGateway public immutable gateway;
   // uint256 public s_maxSupply = 1000000000000000000000000;

constructor(address _gateway, address _gasService) ERC20("GovernanceToken", "GT") ERC20Permit("GovernanceToken") {
    gasService = IAxelarGasService(_gasService);
    gateway = IAxelarGateway(_gateway);
    uint256 s_maxSupply = 1000000000000000000000000;
    _mint(msg.sender, s_maxSupply);
    _mint(address(this), s_maxSupply);
  }

  // This should be permissioned in a real implementation
function setTokenId(bytes32 _tokenId) external {
        tokenId = _tokenId;
    }

function sendInterchain(string calldata destinationChain, bytes calldata to, uint256 amount) payable external {
        if (tokenId == 0) {
            revert(
                "No tokenID set, please configure the interchain token first."
            );
        }
        if (msg.value == 0) {
            revert("Sending interchain requires a native gas payment.");
        }
        address linkerAddress = 0x7cD2E96f5258BB825ad6FC0D200EDf8C99590d30;
        _approve(address(this),linkerAddress, amount);
        IInterchainTokenLinker linker = IInterchainTokenLinker(
            linkerAddress
        );
        linker.sendToken{value: msg.value}(
            tokenId,
            destinationChain,
            to,
            amount
        );
    }


  // The functions below are overrides required by Solidity.

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20Votes) {
    super._burn(account, amount);
  }
}