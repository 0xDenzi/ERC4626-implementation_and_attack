// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MockToken} from "./mock/ERC20Token.sol";

using SafeERC20 for IERC20;

contract Vault is ERC4626 {

    uint256 constant public FEE = 200;
    uint256 constant public FEE_DENOMINATOR = 10000;

    uint256 private collectedFees = 0;

    address public underlyingToken;

    address public owner;

    constructor(MockToken asset) ERC4626(asset) ERC20(
        string(abi.encodePacked("Vault ", asset.name())), 
        string(abi.encodePacked("v", asset.symbol()))
    ) {
            underlyingToken = address(asset);
            owner = msg.sender;
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }
        uint256 assetsWithoutFee = (assets * (FEE_DENOMINATOR - FEE)) / FEE_DENOMINATOR;
        collectedFees += assets - assetsWithoutFee;
        uint256 shares = previewDeposit(assetsWithoutFee);

        _deposit(msg.sender, receiver, assetsWithoutFee, shares);
        return shares;
    }

    function withdraw(uint256 assets, address receiver, address account) public virtual override returns(uint256) {
        uint256 maxAssets = maxWithdraw(account);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(account, assets, maxAssets);
        }

        if (collectedFees >= 10e17) {
            IERC20(underlyingToken).safeTransfer(owner, collectedFees);
            collectedFees = 0;
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, account, assets, shares);

        return shares;
    }
}