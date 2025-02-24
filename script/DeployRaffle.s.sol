//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {}
    
    function deployContract() public returns (Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks->get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subId,config.vrfCoordinatorV2) = createSubscription.createSubscription(config.vrfCoordinatorV2);
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinatorV2,
            config.gaslane,
            config.subId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}