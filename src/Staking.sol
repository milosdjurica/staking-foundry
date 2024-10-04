// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StakingToken} from "./StakingToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Staking {
    uint256 public constant MINIMUM_STAKING_PERIOD = 180 days;

    StakingToken public immutable i_stakingToken;
    AggregatorV3Interface public immutable i_priceFeed;

    constructor(address stakingTokenAddr_, address priceFeedAddr_) {
        i_stakingToken = StakingToken(stakingTokenAddr_);
        i_priceFeed = AggregatorV3Interface(priceFeedAddr_);
    }

    function stakeETH() external {
        // ! Check errors
        // ! Calculate price
        // ! Update storage
        // ! Give tokens
        // ! Emit
    }
    // ! Add Multiple staking

    function unstakeETH() external {
        // ! Check errors
        // ! Update storage
        // ! Send ETH
        // ! Emit
    }
    // ! Partial unstake
}
