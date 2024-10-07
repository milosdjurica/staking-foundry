// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StakingToken} from "../src/StakingToken.sol";
import {Staking} from "../src/Staking.sol";

contract StakingTokenUnitTests is Test {
    StakingToken stakingToken;
    Staking staking;

    address payable USER = payable(makeAddr("USER"));

    function setUp() public {
        stakingToken = new StakingToken();
        // staking = new Staking(address(stakingToken), address(0));
        staking = new Staking(address(stakingToken));
        stakingToken.transferOwnership(address(staking));

        vm.deal(USER, 100 ether);
    }

    function test_stakingToken_InitsSuccessfully() public view {
        assertEq(stakingToken.name(), "StakingToken");
        assertEq(stakingToken.symbol(), "STK");
    }

    function test_stakeETH_Success() public {
        // ! Test amount of tokens that user gets
        vm.prank(USER);
        staking.stakeETH{value: 1 ether}(181 days, 181 days);
        console2.log(stakingToken.balanceOf(USER) / 1e18);
    }
}
