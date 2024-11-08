// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // EMPTY
    }

    function mint(address account, uint256 amount) public {
        super._mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        super._burn(account, amount);
    }
}