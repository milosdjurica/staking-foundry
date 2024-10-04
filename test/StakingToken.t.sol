// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StakingToken} from "../src/StakingToken.sol";

contract StakingTokenUnitTests is Test {
    StakingToken public stakingToken;

    function setUp() public {
        stakingToken = new StakingToken();
    }

    function test_stakingToken_InitsSuccessfully() public view {
        assertEq(stakingToken.name(), "StakingToken");
        assertEq(stakingToken.symbol(), "STK");
    }
}
