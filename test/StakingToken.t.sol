// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StakingToken} from "../src/StakingToken.sol";

contract StakingTokenUnitTests is Test {
    StakingToken public stakingToken;

    function setUp() public {
        stakingToken = new StakingToken();
    }

    function test_stakingToken_InitsSuccessfully() public {
        assertEq(1, 1);
    }

    // function test_Increment() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
