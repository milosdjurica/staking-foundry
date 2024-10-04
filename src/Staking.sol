// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StakingToken} from "./StakingToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Staking {
    error Staking__AmountMustBeMoreThanZero();

    uint256 public constant MINIMUM_LOCK_PERIOD = 180 days;
    uint256 public constant MINIMUM_UNLOCKING_PERIOD = 180 days;

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

    function stakeETH() external payable moreThanZero(msg.value) {
        // ! Check errors
        // ! Calculate price
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
}
