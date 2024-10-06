// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StakingToken} from "./StakingToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Staking {
    error Staking__AmountMustBeMoreThanZero();
    error Staking__LockPeriodTooShort();
    error Staking__UnlockPeriodTooShort();
    error Staking__LockPeriodNotFinished();
    error Staking__TransferFailed();

    struct StakingInfo {
        uint256 startAmount;
        uint256 startTimestamp;
        uint256 lockPeriod;
        uint256 unlockPeriod;
        uint256 currentAmount;
        uint256 lastUpdate;
    }

    uint256 public constant MINIMUM_LOCK_PERIOD = 180 days;
    uint256 public constant MINIMUM_UNLOCK_PERIOD = 180 days;
    uint256 public constant EIGHTEEN_DECIMALS = 1e18;

    StakingToken public immutable i_stakingToken;
    AggregatorV3Interface public immutable i_priceFeed;

    mapping(address => mapping(uint256 => StakingInfo)) public userStakings;
    mapping(address => uint256) public userStakingCount;

    event Staked(address indexed who, uint256 indexed amount, uint256 indexed lockPeriod, uint256 unlockPeriod);
    event Unstaked(address indexed who, uint256 indexed stakingId, uint256 indexed amount);

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert Staking__AmountMustBeMoreThanZero();
        _;
    }

    constructor(address stakingTokenAddr_, address priceFeedAddr_) {
        i_stakingToken = StakingToken(stakingTokenAddr_);
        i_priceFeed = AggregatorV3Interface(priceFeedAddr_);
    }

    function stakeETH(uint256 lockPeriod_, uint256 unlockPeriod_) external payable moreThanZero(msg.value) {
        if (lockPeriod_ < MINIMUM_LOCK_PERIOD) revert Staking__LockPeriodTooShort();
        if (unlockPeriod_ < MINIMUM_UNLOCK_PERIOD) revert Staking__UnlockPeriodTooShort();
        uint256 tokenAmount = _getTokenAmount(msg.value);
        uint256 stakingId = userStakingCount[msg.sender];

        userStakings[msg.sender][stakingId] =
            StakingInfo(msg.value, block.timestamp, lockPeriod_, unlockPeriod_, msg.value, block.timestamp);
        userStakingCount[msg.sender]++;

        i_stakingToken.mint(msg.sender, tokenAmount);
        emit Staked(msg.sender, msg.value, lockPeriod_, unlockPeriod_);
    }

    function unstakeETH(uint256 amount_, uint256 stakingId_) external moreThanZero(amount_) {
        StakingInfo memory sInfo = userStakings[msg.sender][stakingId_];
        uint256 unlockingStart = sInfo.startTimestamp + sInfo.lockPeriod;
        uint256 unlockingEnd = unlockingStart + sInfo.unlockPeriod;

        if (sInfo.currentAmount == 0) revert Staking__AmountMustBeMoreThanZero();
        if (sInfo.startTimestamp + sInfo.lockPeriod > block.timestamp) revert Staking__LockPeriodNotFinished();

        uint256 canUnstakeAmount;
        if (block.timestamp > unlockingEnd) {
            canUnstakeAmount = i_stakingToken.balanceOf(msg.sender);
        } else {
            canUnstakeAmount =
                sInfo.startAmount * (block.timestamp - sInfo.lastUpdate) / (unlockingEnd - sInfo.startTimestamp);
        }

        if (amount_ > canUnstakeAmount) amount_ = canUnstakeAmount;
        // ! Update storage
        sInfo.currentAmount -= amount_;
        sInfo.lastUpdate = block.timestamp;

        (bool success,) = msg.sender.call{value: amount_}("");
        if (!success) revert Staking__TransferFailed();
        // ! Emit
        emit Unstaked(msg.sender, stakingId_, amount_);
    }

    /**
     *
     * @param amount_ amount of ETH
     */
    function _getTokenAmount(uint256 amount_) internal view returns (uint256) {
        (, int256 price,,,) = i_priceFeed.latestRoundData();
        return amount_ * uint256(price) / i_priceFeed.decimals();
    }
}
