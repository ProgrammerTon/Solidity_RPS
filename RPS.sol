// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";
import "./Convert.sol";

contract RPS is CommitReveal, TimeUnit {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Spock , 2 - Paper , 3 - Lizard , 4 - Scissors
    mapping(address => bool) public player_not_played;
    address[] public players;
    address[4] public real_players = [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 
    0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 
    0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB]; // 4 Accounts that we allow

    uint public numInput = 0;

    function addPlayer() public payable {
        require(numPlayer < 2);
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        bool allow = false;
        for (uint i = 0; i < real_players.length; i++) {
            if (msg.sender == real_players[i]) {
                allow = true;
                break;
            }
        } // Check player account only real_players that we accept 
        require(allow == true);
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    function input(uint choice) public  {
        require(numPlayer == 2);
        require(player_not_played[msg.sender]);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4); // Add choices for Lizard and Spock
        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        // 0 Rock beats 4 Scissors 3 Lizard 
        // 1 Spock beats 0 Rock 4 Scissors
        // 2 Paper beats 1 Spock 0 Rock
        // 3 Lizard beats 2 Paper 1 Spock
        // 4 Scissors beats 3 Lizard 2 Paper
        // As you can see with this we can use (p0Choice + 1) % 5 == p1Choice for the first beat and (p0Choice + 3) % 5 for the second beat
        if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 3) % 5 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 3) % 5 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        newRound(); // Enter New Round
    }

    // function for newRound will always be called after we pay the winner in previous round
    function newRound() private {
        numPlayer = 0;
        reward = 0;
        player_choice[players[0]] = 0;
        player_choice[players[1]] = 0;
        player_not_played[players[0]] = true;
        player_not_played[players[1]] = true;
        numInput = 0;
    }
}
