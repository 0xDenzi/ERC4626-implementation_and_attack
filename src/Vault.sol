// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {MockToken} from "./mock/ERC20Token.sol";

contract Vault is ERC4626 {
    constructor(MockToken asset) ERC4626(asset) ERC20(
        string(abi.encodePacked("Vault ", asset.name())), 
        string(abi.encodePacked("v", asset.symbol()))
    ) {
            
    }
}