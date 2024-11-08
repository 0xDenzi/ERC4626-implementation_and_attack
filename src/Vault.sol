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

    event FeesCollected(uint256 amount);

    constructor(MockToken asset) ERC4626(asset) ERC20(
        string(abi.encodePacked("Vault ", asset.name())), 
        string(abi.encodePacked("v", asset.symbol()))
    ) {
            underlyingToken = address(asset);
            owner = msg.sender;
    }
    
    function totalAssets() public view virtual override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) - collectedFees;
    }

    function _calculateFee(uint256 amount) internal pure returns(uint256) {
        return (amount * FEE) / FEE_DENOMINATOR;
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
        
        uint256 fee = _calculateFee(assets);
        uint256 assetsAfterFee = assets - fee;
        collectedFees += fee;

        uint256 shares = previewDeposit(assetsAfterFee);

        _deposit(_msgSender(), receiver, assetsAfterFee, shares);

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

        if (collectedFees >= 10e17) {
            IERC20(underlyingToken).safeTransfer(owner, collectedFees);
            emit FeesCollected(collectedFees);
            collectedFees = 0;
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, account, assets, shares);

        return shares;
    }
}