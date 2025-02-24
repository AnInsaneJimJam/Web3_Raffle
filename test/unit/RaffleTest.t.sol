//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

// import {Raffle, DeployRaffle, HelperConfig} from "script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinatorV2;
    bytes32 gaslane;
    uint256 subId;
    uint32 callbackGasLimit;

    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinatorV2 = config.vrfCoordinatorV2;
        gaslane = config.gaslane;
        subId = config.subId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert((raffle.raffleState()) == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenNotEnoughEthSent() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    /////////////////////////////////CHECK UPKEEP FUNCTIONS///////////////////////////////////////////////////////////////////////////////////////

    function testCheckUpKeepReturnFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnFalseIfRaffleIsNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    // testCheckUpkeepReturnsFalseIfEnoughTimeHasPassed
    // testCheckUpkeepReturnsTrueWhenParamsAreGood

    /////////////////////////////PERFORM UP KEEP/////////////////////////////////////////////////////////////////////////////////////////////////

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
        raffle.performUpKeep("");
        (upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded); 
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public{
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.raffleState();

    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    currentBalance= currentBalance + entranceFee;
    numPlayers = 1;


    vm.expectRevert(
        abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector, currentBalance,numPlayers,rState)
    );
    raffle.performUpKeep("");
}
}