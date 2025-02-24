//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns (uint256 , address){

        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2;
        //Create Subscription
        (uint256 subId,) = createSubscription(vrfCoordinator);
        return(subId, vrfCoordinator);

    }

    function createSubscription(address vrfCoordinator) public returns (uint256 , address) {
        console.log("Creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Subscription created with subId: ", subId);
        console.log("Please update the subId in the config file");

        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {

    uint256 public constant LINK_AMOUNT = 3 ether;// 3 lINK

    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2;
        uint256 subId = helperConfig.getConfig().subId;
    }

    function run() public{}
}