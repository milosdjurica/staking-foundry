// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StakingToken} from "./StakingToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Staking {
    error Staking__AmountMustBeMoreThanZero();
    error Staking__LockPeriodTooShort();
    error Staking__UnlockPeriodTooShort();

    uint256 public constant MINIMUM_LOCK_PERIOD = 180 days;
    uint256 public constant MINIMUM_UNLOCK_PERIOD = 180 days;
    uint256 public constant EIGHTEEN_DECIMALS = 1e18;

    StakingToken public immutable i_stakingToken;
    AggregatorV3Interface public immutable i_priceFeed;

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert Staking__AmountMustBeMoreThanZero();
        _;
    }

    constructor(address stakingTokenAddr_, address priceFeedAddr_) {
        i_stakingToken = StakingToken(stakingTokenAddr_);
        i_priceFeed = AggregatorV3Interface(priceFeedAddr_);
    }

    function stakeETH(uint256 lockPeriod_, uint256 unlockPeriod_) external payable moreThanZero(msg.value) {
        // ! Check errors
        if (lockPeriod_ < MINIMUM_LOCK_PERIOD) revert Staking__LockPeriodTooShort();
        if (unlockPeriod_ < MINIMUM_UNLOCK_PERIOD) revert Staking__UnlockPeriodTooShort();
        // ! Calculate price
        uint256 tokenAmount = _getTokenAmount(msg.value);
        // ! Update storage
        // ! Give tokens
        // ! Emit
    }
    // ! Add Multiple staking

    function unstakeETH(uint256 amount_) external moreThanZero(amount_) {
        // ! Check errors
        // ! Update storage
        // ! Send ETH
        // ! Emit
    }
    // ! Partial unstake

    function _getTokenAmount(uint256 amount_) internal view returns (uint256) {
        (, int256 price,,,) = i_priceFeed.latestRoundData();
        return amount_ * uint256(price) / i_priceFeed.decimals();
    }
}
