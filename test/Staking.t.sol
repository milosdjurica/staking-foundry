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

    event Staked(address indexed who, uint256 indexed amount, uint256 indexed lockPeriod, uint256 unlockPeriod);

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
        staking.stakeETH(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
    }

    function test_stakeETH_RevertIf_lockPeriodTooShort() public {
        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__LockPeriodTooShort.selector));
        staking.stakeETH{value: 1 ether}(0, MINIMUM_UNLOCK_PERIOD);
    }

    function test_stakeETH_RevertIf_unlockPeriodTooShort() public {
        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__UnlockPeriodTooShort.selector));
        staking.stakeETH{value: 1 ether}(MINIMUM_LOCK_PERIOD, 0);
    }

    function test_stakeETH_Success() public {
        vm.prank(USER);
        // ! Expect emit
        vm.expectEmit(true, true, true, true, address(staking));
        emit Staked(USER, ONE_ETHER, MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        staking.stakeETH{value: ONE_ETHER}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);

        (
            uint256 startTimestampReal,
            uint256 lockPeriodReal,
            uint256 unlockPeriodReal,
            uint256 amountReal,
            uint256 lastUpdateReal
        ) = staking.userStakingsInfo(USER, 0);

        assertEq(startTimestampReal, block.timestamp);
        assertEq(lockPeriodReal, MINIMUM_LOCK_PERIOD);
        assertEq(unlockPeriodReal, MINIMUM_UNLOCK_PERIOD);
        assertEq(amountReal, ONE_ETHER);
        assertEq(lastUpdateReal, block.timestamp + MINIMUM_LOCK_PERIOD);

        assertEq(staking.userStakingCount(USER), 1);
        assertEq(stakingToken.balanceOf(USER), ONE_ETHER * NUM_OF_TOKENS_PER_ETH);
    }

    function test_stakeETH_userMultipleStakes() public {
        vm.startPrank(USER);
        staking.stakeETH{value: 1 ether}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        staking.stakeETH{value: 1 ether}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        (,,, uint256 amountStaked,) = staking.userStakingsInfo(USER, 0);

        assertEq(stakingToken.balanceOf(USER), 2 ether * 100);
        assertEq(staking.userStakingCount(USER), 2);
        assertEq(amountStaked, 1 ether);
        vm.stopPrank();
    }

    function test_unstakeETH_RevertIf_amountIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__AmountMustBeMoreThanZero.selector));
        staking.unstakeETH(0, 1);
    }

    function test_unstakeETH_RevertIf_lockPeriodNotFinished() public {
        vm.startPrank(USER);
        staking.stakeETH{value: ONE_ETHER}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);

        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__LockPeriodNotFinished.selector));
        staking.unstakeETH(ONE_ETHER, 0);

        vm.stopPrank();
    }

    function test_unstakeETH_RevertIf_nothingStaked() public {
        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__NothingIsStaked.selector));
        staking.unstakeETH(ONE_ETHER, 1);
    }

    function test_unstakeETH_RevertIf_cantUnstakeAfterEverythingIsUnstakedAlready() public {
        vm.startPrank(USER);
        staking.stakeETH{value: ONE_ETHER}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        skip(MINIMUM_LOCK_PERIOD + MINIMUM_UNLOCK_PERIOD);

        staking.unstakeETH(ONE_ETHER, 0);

        vm.expectRevert(abi.encodeWithSelector(Staking.Staking__NothingIsStaked.selector));
        staking.unstakeETH(ONE_ETHER, 0);

        vm.stopPrank();
    }

    function test_unstakeETH_partialUnstake1() public {
        vm.startPrank(USER);

        staking.stakeETH{value: ONE_ETHER}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        skip(MINIMUM_LOCK_PERIOD + MINIMUM_UNLOCK_PERIOD / 2);

        staking.unstakeETH(ONE_ETHER, 0);
        vm.stopPrank();

        assertEq(stakingToken.balanceOf(USER), ONE_ETHER * 100 / 2);
    }

    function test_unstakeETH_partialUnstake2() public {
        vm.startPrank(USER);

        staking.stakeETH{value: ONE_ETHER}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        skip(MINIMUM_LOCK_PERIOD + MINIMUM_UNLOCK_PERIOD / 2);

        staking.unstakeETH(ONE_ETHER, 0);
        skip(MINIMUM_UNLOCK_PERIOD);
        staking.unstakeETH(ONE_ETHER, 0);

        vm.stopPrank();

        assertEq(stakingToken.balanceOf(USER), 0);
    }

    function test_unstakeETH_partialUnstake3() public {
        vm.startPrank(USER);

        staking.stakeETH{value: ONE_ETHER}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        skip(MINIMUM_LOCK_PERIOD + MINIMUM_UNLOCK_PERIOD / 2);
        staking.unstakeETH(ONE_ETHER, 0);
        assertEq(stakingToken.balanceOf(USER), ONE_ETHER * 100 / 2);

        skip(MINIMUM_UNLOCK_PERIOD / 10);
        staking.unstakeETH(ONE_ETHER, 0);
        // ! 40 % left
        assertEq(stakingToken.balanceOf(USER), ONE_ETHER * 100 * 40 / 100);

        skip(MINIMUM_UNLOCK_PERIOD / 5);
        staking.unstakeETH(ONE_ETHER, 0);
        // ! 20% left
        assertEq(stakingToken.balanceOf(USER), ONE_ETHER * 100 * 20 / 100);
        skip(MINIMUM_UNLOCK_PERIOD / 5);
        staking.unstakeETH(ONE_ETHER, 0);
        (,,, uint256 amountReal, uint256 lastUpdateReal) = staking.userStakingsInfo(USER, 0);
        assertEq(amountReal, 0);
        assertEq(lastUpdateReal, block.timestamp);
        assertEq(stakingToken.balanceOf(USER), 0);
        vm.stopPrank();
    }

    function test_calculateCanUnstakeAmount_blockTimestampHigher1() public view {
        uint256 amount = staking.calculateCanUnstakeAmount(
            Staking.StakingInfo(
                block.timestamp, MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD, 1 ether, MINIMUM_LOCK_PERIOD
            )
        );
        assertEq(amount, 0);
    }

    function test_calculateCanUnstakeAmount_blockTimestampHigher2() public {
        skip(MINIMUM_LOCK_PERIOD + MINIMUM_UNLOCK_PERIOD / 2);

        uint256 amount = staking.calculateCanUnstakeAmount(
            // ! TODO why 2 ???
            Staking.StakingInfo(2, MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD, 1 ether, MINIMUM_LOCK_PERIOD)
        );
        assertEq(amount, 0.5 ether);
    }

    function test_calculateCanUnstakeAmount_blockTimestampHigher3() public {
        skip(MINIMUM_LOCK_PERIOD + MINIMUM_UNLOCK_PERIOD + 2);

        uint256 amount = staking.calculateCanUnstakeAmount(
            Staking.StakingInfo(1, MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD, 1 ether, MINIMUM_LOCK_PERIOD)
        );
        assertEq(amount, 1 ether);
    }

    function test_stakeETH_userMultipleStakesWithPartialUnstake() public {
        vm.startPrank(USER);
        staking.stakeETH{value: 1 ether}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        staking.stakeETH{value: 1 ether}(MINIMUM_LOCK_PERIOD, MINIMUM_UNLOCK_PERIOD);
        skip(MINIMUM_LOCK_PERIOD + MINIMUM_UNLOCK_PERIOD);
        staking.unstakeETH(ONE_ETHER / 2, 0);

        assertEq(stakingToken.balanceOf(USER), 1.5 ether * 100);
        assertEq(staking.userStakingCount(USER), 2);
        (,,, uint256 amountStaked,) = staking.userStakingsInfo(USER, 0);
        assertEq(amountStaked, 0.5 ether);
        vm.stopPrank();
    }

    // TODO -> check multiple staking(one user many stakes, different users stakings), fuzz tests, integration tests, invariant tests
}
