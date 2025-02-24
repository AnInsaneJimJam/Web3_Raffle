// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions


// CEI: Checks, Effects, Interactions

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// import {AutomationCompatibleInterface} from
//     "@chainlink/contracts/src/v0.8/automation//interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A Simple Raffle Contract
 * @author Anand :)
 * @notice This contract is a simple raffle contract
 * @dev Implements Chainlink VRF
 */
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughEthSent();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /**
     * Type Declarations
     */
    enum RaffleState {
        OPEN, 
        CALCULATING}

    /**
     * State Variables
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFConsumerBaseV2Plus private immutable i_vrfCoordinator;
    bytes32 private immutable i_gaslane;
    uint256 private immutable i_subId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinenr;
    RaffleState private s_raffleState;

    

    /**
     * Events
     */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorV2,
        bytes32 gaslane,
        uint256 subId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_gaslane = gaslane;
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;
        i_vrfCoordinator = VRFConsumerBaseV2Plus(vrfCoordinatorV2);
        s_raffleState = RaffleState.OPEN;
    }

    //  Doing external instead of public becuase this won't be used anywhere else in the contract(Saves Gas)
    function enterRaffle() external payable {
        // require(msg.value > i_entranceFee, "Not enough ETH to enter the raffle");
        //Revert is better for saving gas
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Use the random number to pick a winner
    // 3. Be automatically called - Automation 


    /**
     * @dev This is the function that the chainlink node will call to see if the lottery is ready to have winner picked.
     * The following should be true in order for upkeppNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */) public view returns(bool upkeepNeeded, bytes memory /* performData */){
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");

    } 
                                                              

    //function pickWinner() external {
        function performUpKeep(bytes calldata /*performData */ )external {
        // Check to see if enough time has passed
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        //1. Request the RNG
        // 2. Get the random number
        // 3. Pick a winner
        s_raffleState = RaffleState.CALCULATING; 
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gaslane,
                subId: i_subId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false})) // new parameter
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinenr = recentWinner;

        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(s_recentWinenr);

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    /**
     * Getters
     */
    function entranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function raffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}