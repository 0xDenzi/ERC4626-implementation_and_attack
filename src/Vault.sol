// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MockToken} from "./mock/ERC20Token.sol";

using SafeERC20 for IERC20;

contract Vault is ERC4626 {

    address public underlyingToken;
    address public owner;

    event FeesCollected(uint256 amount);

    constructor(MockToken asset) ERC4626(asset) ERC20(
        string(abi.encodePacked("Vault ", asset.name())), 
        string(abi.encodePacked("v", asset.symbol()))
    ) {
            underlyingToken = address(asset);
            owner = msg.sender;
    }
    
    function totalAssets() public view virtual override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function checkShares() public view virtual returns (uint256) {
        return balanceOf(_msgSender());
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override returns (uint256) {

        require(assets > 0, "Cannot deposit 0 assets");
        require(receiver != address(0), "Invalid receiver");

        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);

        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function withdraw(uint256 assets, address receiver, address account) public virtual override returns(uint256) {

        require(assets > 0, "Cannot withdraw 0 assets");
        require(receiver != address(0), "Invalid receiver");
        require(account != address(0), "Invalid account");

        uint256 maxAssets = maxWithdraw(account);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(account, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, account, assets, shares);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address account) public virtual override returns (uint256) {
        uint256 maxShares = maxRedeem(account);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(account, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, account, assets, shares);

        return assets;
    }
}