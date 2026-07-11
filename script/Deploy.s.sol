// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {DestinationVault} from "../src/DestinationVault.sol";

contract DeploySource is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new SourceVault(
            vm.envAddress("CCIP_ROUTER_SOURCE"),
            vm.envAddress("LINK_SOURCE"),
            vm.envAddress("TOKEN_SOURCE"),
            uint64(vm.envUint("DEST_CHAIN_SELECTOR")),
            vm.envAddress("DEST_VAULT_ADDRESS")
        );
        vm.stopBroadcast();
    }
}

contract DeployDestination is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new DestinationVault(
            vm.envAddress("CCIP_ROUTER_DEST"),
            vm.envAddress("SOURCE_VAULT_ADDRESS"),
            uint64(vm.envUint("SOURCE_CHAIN_SELECTOR"))
        );
        vm.stopBroadcast();
    }
}
