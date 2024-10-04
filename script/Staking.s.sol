// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

contract StakingDeployScript is Script {
    string public constant SEPOLIA_PRICE_FEED_ADDRESS = "0x694aa1769357215de4fac081bf1f309adc325306";

    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}
