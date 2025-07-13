// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Delegation} from "../src/Contract.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Delegation delegation = new Delegation();

        // Initialize the contract
        delegation.initialize();

        vm.stopBroadcast();

        console.log("Delegation deployed at:", address(delegation));
    }
}
