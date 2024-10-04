// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StakingToken} from "./StakingToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Staking {
    StakingToken public immutable i_stakingToken;
    AggregatorV3Interface public immutable i_priceFeed;

    constructor(address stakingTokenAddr_, address priceFeedAddr_) {
        i_stakingToken = StakingToken(stakingTokenAddr_);
        i_priceFeed = AggregatorV3Interface(priceFeedAddr_);
    }
}
