//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "./utils/AdminRights.sol";
import "./model/Character.sol";
import "./model/Boss.sol";
import "./utils/PseudoRandom.sol";

error CharacterAlreadyInGame();

/// @title World of Ledger
/// @author William Veal Phan
contract Game is AdminRights, PseudoRandom {
    /// @notice owner of the contract
    /// @dev owner never changes
    address public immutable owner;

    /// @dev id of the last boss created; if eq 0, no boss exists
    uint256 bossId = 0;

    /// @notice bosses currently in the game
    mapping(uint256 id => Boss boss) public bosses;

    /// @notice base health of a character
    uint256 public characterBaseHealth = 100;
    /// @notice max health bonus of a character; a new character hp will be in [ base - dev, base + dev ]
    uint256 public characterBaseHealthDeviation = 10;
    /// @notice base damage of a character
    uint256 public characterBaseDamage = 10;
    /// @notice max damage bonus of a character; a new character damage will be in [ base - dev, base + dev ]
    uint256 public characterBaseDamageDeviation = 5;

    /// @notice characters currently in the game ; only one character is allowed per address
    mapping(address user => Character character) public characters;

    constructor() {
        // owner is the deployer of this contract
        owner = msg.sender;
        // owner inherit admin rights by default
        admin = msg.sender;
    }

    /// @notice create a custom boss and add it to the game; need admin rights
    /// @dev increment bossId and add a new boss to the bosses mapping
    /// @param _hp new boss starting hp
    /// @param _damage new boss damage
    /// @param _reward new boss reward
    /// @return bossId ID of the newly created boss
    function createBoss(uint256 _hp, uint256 _damage, uint256 _reward) external onlyAdmin returns (uint256) {
        bossId++;
        bosses[bossId] = Boss(_hp, _damage, _reward);
        return bossId;
    }

    /// @notice Create a new semi random character; only one character per address
    /// @return senderAddress address of the newly created character
    function createCharacter() external returns (address) {
        if (characters[msg.sender].hp > 0) revert CharacterAlreadyInGame();
        uint256 hp = characterBaseHealth + random(characterBaseHealthDeviation) - random(characterBaseHealthDeviation);
        uint256 dmg = characterBaseDamage + random(characterBaseDamageDeviation) - random(characterBaseDamageDeviation);
        characters[msg.sender] = Character(hp, dmg, 0);
        return msg.sender;
    }
}
