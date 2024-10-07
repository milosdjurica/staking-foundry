// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StakingToken} from "./StakingToken.sol";

contract Staking {
    error Staking__AmountMustBeMoreThanZero();
    error Staking__LockPeriodTooShort();
    error Staking__UnlockPeriodTooShort();
    error Staking__LockPeriodNotFinished();
    error Staking__TransferFailed();
    error Staking__NothingIsStaked();

    struct StakingInfo {
        // TODO -> Simplify this struct even more if possible
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

    StakingToken public immutable i_stakingToken;

    mapping(address => mapping(uint256 => StakingInfo)) public userStakingsInfo;
    mapping(address => uint256) public userStakingCount;

    event Staked(address indexed who, uint256 indexed amount, uint256 indexed lockPeriod, uint256 unlockPeriod);
    event Unstaked(address indexed who, uint256 indexed stakingId, uint256 indexed amount);

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert Staking__AmountMustBeMoreThanZero();
        _;
    }

    constructor(address stakingTokenAddr_) {
        i_stakingToken = StakingToken(stakingTokenAddr_);
    }

    function stakeETH(uint256 lockPeriod_, uint256 unlockPeriod_) external payable moreThanZero(msg.value) {
        if (lockPeriod_ < MINIMUM_LOCK_PERIOD) revert Staking__LockPeriodTooShort();
        if (unlockPeriod_ < MINIMUM_UNLOCK_PERIOD) revert Staking__UnlockPeriodTooShort();
        uint256 stakingId = userStakingCount[msg.sender];

        // ! CHANGED -> lastUpdate == BLOCK TIMESTAMP + LOCK PERIOD !!!!
        userStakingsInfo[msg.sender][stakingId] =
            StakingInfo(block.timestamp, lockPeriod_, unlockPeriod_, msg.value, block.timestamp + lockPeriod_);
        userStakingCount[msg.sender]++;

        uint256 tokenAmount = msg.value * NUM_OF_TOKENS_PER_ETH;
        i_stakingToken.mint(msg.sender, tokenAmount);
        emit Staked(msg.sender, msg.value, lockPeriod_, unlockPeriod_);
    }

    // TODO -> optimize
    function unstakeETH(uint256 amount_, uint256 stakingId_) external moreThanZero(amount_) {
        StakingInfo memory sInfo = userStakingsInfo[msg.sender][stakingId_];

        if (sInfo.amountStaked == 0) revert Staking__NothingIsStaked();
        if (sInfo.startTimestamp + sInfo.lockPeriod > block.timestamp) revert Staking__LockPeriodNotFinished();

        uint256 canUnstakeAmount = calculateCanUnstakeAmount(sInfo);
        if (amount_ > canUnstakeAmount) amount_ = canUnstakeAmount;

        sInfo.amountStaked -= amount_;
        sInfo.lastUpdate = block.timestamp;
        userStakingsInfo[msg.sender][stakingId_] = sInfo;
        emit Unstaked(msg.sender, stakingId_, amount_);

        i_stakingToken.burn(msg.sender, amount_ * NUM_OF_TOKENS_PER_ETH);
        (bool success,) = msg.sender.call{value: amount_}("");
        if (!success) revert Staking__TransferFailed();
    }

    function calculateCanUnstakeAmount(StakingInfo memory sInfo_) public view returns (uint256) {
        uint256 unlockingEndTimestamp = sInfo_.startTimestamp + sInfo_.lockPeriod + sInfo_.unlockPeriod;
        return block.timestamp > unlockingEndTimestamp
            ? sInfo_.amountStaked
            : sInfo_.amountStaked * (block.timestamp - sInfo_.lastUpdate) / (unlockingEndTimestamp - sInfo_.lastUpdate);
    }
}
