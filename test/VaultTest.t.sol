// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {MockToken} from "../src/mock/ERC20Token.sol";

contract VaultTest is Test {
    Vault public vault;
    MockToken public token;

    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    uint256 constant INITIAL_BALANCE = 100e18;
    uint256 constant FEE = 200;
    uint256 constant FEE_DENOMINATOR = 10000;

    function setUp() public {
        vm.startPrank(owner);

        token = new MockToken("Mock Token", "MKT");
        vault = new Vault(token);
        vm.stopPrank();   
        
        token.mint(user1, INITIAL_BALANCE);
        token.mint(user2, INITIAL_BALANCE);
    }

    function test_InitialState() public view {
        assertEq(address(vault.asset()), address(token));
        assertEq(vault.owner(), owner);
        assertEq(vault.totalAssets(), 0);
    }

    function test_DepositSuccessful() public {
        uint256 depositAmount = 100e18;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);

        uint256 shares = vault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), INITIAL_BALANCE - depositAmount);
        assertEq(token.balanceOf(address(vault)), depositAmount);
        assertEq(vault.balanceOf(user1), shares);
    }

    function test_WithdrawSuccessful() public {
        uint256 depositAmount = 100e18;

        vm.startPrank(user1);
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), INITIAL_BALANCE - depositAmount);
        assertEq(token.balanceOf(address(vault)), depositAmount);
        assertEq(vault.balanceOf(user1), shares);

        uint256 withdrawAmount = depositAmount / 2;
        uint256 expectedShares = vault.previewWithdraw(withdrawAmount);

        vm.startPrank(user1);
        vault.withdraw(withdrawAmount, user1, user1);

        assertEq(vault.balanceOf(user1), shares - expectedShares);
        assertEq(token.balanceOf(user1), INITIAL_BALANCE - depositAmount + withdrawAmount);
        assertEq(token.balanceOf(address(vault)), depositAmount - withdrawAmount);
    }
}