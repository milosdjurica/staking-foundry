// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {StakingToken, Staking} from "../src/Staking.sol";

contract StakingDeployScript is Script {
    function run() public returns (StakingToken, Staking) {
        vm.startBroadcast();

        StakingToken stakingToken = new StakingToken();
        Staking staking = new Staking(address(stakingToken));

        stakingToken.transferOwnership(address(staking));

        vm.stopBroadcast();

        return (stakingToken, staking);
    }
}
