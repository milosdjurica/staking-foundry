// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StakingToken, Ownable} from "../src/StakingToken.sol";
import {Staking} from "../src/Staking.sol";
import {StakingDeployScript} from "../script/Staking.s.sol";

contract StakingUnitTests is Test {
    StakingToken stakingToken;
    Staking staking;
    StakingDeployScript stakingDeployScript;

    struct StakingInfo {
        uint256 startTimestamp;
        uint256 lockPeriod;
        uint256 unlockPeriod;
        uint256 amountStaked;
        uint256 lastUpdate;
    }

    uint256 public constant MINIMUM_LOCK_PERIOD = 180 days;
    uint256 public constant MINIMUM_UNLOCK_PERIOD = 180 days;
    uint256 public constant EIGHTEEN_DECIMALS = 1e18;
    uint256 public constant NUM_OF_TOKENS_PER_ETH = 100;
    uint256 public constant ONE_ETHER = 1 ether;

    address payable USER = payable(makeAddr("USER"));

    function setUp() public {
        stakingDeployScript = new StakingDeployScript();
        (stakingToken, staking) = stakingDeployScript.run();

        vm.deal(USER, 100 ether);
    }

    // ! StakingToken unit tests

    function test_stakingToken_InitsSuccessfully() public view {
        assertEq(stakingToken.name(), "StakingToken");
        assertEq(stakingToken.symbol(), "STK");
        assertEq(stakingToken.owner(), address(staking));
    }

    function test_stakingToken_mint_RevertIf_NotOwner() public {
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        stakingToken.mint(USER, 10);
    }

    function test_stakingToken_burn_RevertIf_NotOwner() public {
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        stakingToken.burn(USER, 10);
    }

    // ! Staking tests
    function test_constructor_initsSuccessfully() public view {
        assertEq(address(staking.i_stakingToken()), address(stakingToken));
    }

    function test_stakeETH_RevertIf_amount0() public {
        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__AmountMustBeMoreThanZero.selector));
        staking.stakeETH(MINIMUM_LOCK_PERIOD + 1, MINIMUM_UNLOCK_PERIOD + 1);
    }

    function test_stakeETH_RevertIf_lockPeriodTooShort() public {
        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__LockPeriodTooShort.selector));
        staking.stakeETH{value: 1 ether}(0, MINIMUM_UNLOCK_PERIOD + 1);
    }

    function test_stakeETH_RevertIf_unlockPeriodTooShort() public {
        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__UnlockPeriodTooShort.selector));
        staking.stakeETH{value: 1 ether}(MINIMUM_LOCK_PERIOD + 1, 0);
    }

    function test_stakeETH_Success() public {
        vm.prank(USER);
        // ! Expect emit
        staking.stakeETH{value: ONE_ETHER}(MINIMUM_LOCK_PERIOD + 1, MINIMUM_UNLOCK_PERIOD + 1);

        (
            uint256 startTimestampReal,
            uint256 lockPeriodReal,
            uint256 unlockPeriodReal,
            uint256 amountReal,
            uint256 lastUpdateReal
        ) = staking.userStakingsInfo(USER, 0);

        assertEq(startTimestampReal, block.timestamp);
        assertEq(lockPeriodReal, MINIMUM_LOCK_PERIOD + 1);
        assertEq(unlockPeriodReal, MINIMUM_UNLOCK_PERIOD + 1);
        assertEq(amountReal, ONE_ETHER);
        assertEq(lastUpdateReal, block.timestamp);

        assertEq(staking.userStakingCount(USER), 1);
        assertEq(stakingToken.balanceOf(USER), ONE_ETHER * NUM_OF_TOKENS_PER_ETH);
    }

    function _compareStructs(StakingInfo memory a, StakingInfo memory b) internal pure {
        assertEq(abi.encode(a), abi.encode(b));
    }
}
