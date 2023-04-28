//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "./utils/AdminRights.sol";
import "./model/Character.sol";
import "./model/Boss.sol";
import "./utils/PseudoRandom.sol";
import "./model/Errors.sol";

library GameEvents {
    /// @notice A new boss was added to the game. Fight for your life ! For loot and glory !
    /// @dev emit this when spawning a new boss
    /// @param bossId id of the newly minted boss
    /// @param boss the boss itselft
    event BossSpawned(uint256 bossId, Boss boss);

    /// @notice A boss was slain. Remember the fallen, feast their memory...and enjoy your riches !
    /// @dev emit this when a boss' hp fall to 0
    /// @param bossId id of the slain boss
    event BossVainquished(uint256 bossId);

    /// @notice A user claimed a reward for a boss they helped slay. Each reward can only
    /// @dev emit this when a user claim a reward; update reards states accordingly
    /// @param bossId id of a DEAD boss
    /// @param user address of the user claiming the reward : they MUST be worthy
    /// @param reward amount of exp claimed
    event BossRewardClaimed(uint256 bossId, address user, uint256 reward);

    /// @notice A new hero has joined the field of battle ! Be brave, be strong, be victorious !
    /// @dev Emit this when a new player mint their UNIQUE character
    /// @param user address of the new player
    /// @param character the new pseudo-randomly generated character
    event CharacterCreated(address user, Character character);

    /// @notice A hero has struck a mighty blow to the current boss
    /// @dev Emit this when a player attack the current boss
    /// @param user address of the player
    /// @param bossId id of the current boss
    /// @param damage amount of damage dealt to the boss
    event HeroicFeat(address user, uint256 bossId, uint256 damage);

    /// @notice A hero has been struck by the current boss
    /// @dev Emit this when a player is counter-attacked by the current boss
    /// @param bossId id of the current boss
    /// @param user address of the player who has been struck
    /// @param damage amount of damage dealt to the player
    event Aaaaaaargh(uint256 bossId, address user, uint256 damage);

    /// @notice A hero has fallen in battle
    /// @dev Emit this when a player is slain by the current boss
    /// @param user address of the player who has been slain
    event AHeroHasFallen(address user);
}

/// @title World of Ledger
/// @author William Veal Phan
contract Game is AdminRights, CharacterOps {
    using BossImpl for Boss;
    using CharacterImpl for Character;

    /// @notice owner of the contract
    /// @dev owner never changes
    address public immutable owner;

    uint256 bossId;

    /// @notice current boss in the game
    Boss public boss;

    /// @notice users with characters in game
    mapping(address user => bool hasCharacter) public hasCharacterInGame;

    /// @notice characters currently in the game ; only one character is allowed per address
    mapping(address user => Character character) public characters;

    /// @notice keep track of the status of past, current and future bosses
    mapping(uint256 bossId => Boss boss) public bosses;

    /// @notice keep track of the rewards a boss can give
    mapping(uint256 bossId => uint256 reward) public bossRewards;

    enum RewardStatus {
        Unworthy,
        Unclaimed,
        Claimed
    }

    /// @notice keep track boss fight reward a user can claim
    mapping(address user => mapping(uint256 bossId => RewardStatus status)) public rewards;

    constructor() {
        // owner is the deployer of this contract
        owner = msg.sender;
        // owner inherit admin rights by default
        admin = msg.sender;

        bossId = 0;
    }

    /// @notice create a custom boss and add it to the game; need admin rights
    /// @dev increment bossId and add a new boss to the bosses mapping
    /// @param _hp new boss starting hp
    /// @param _damage new boss damage
    /// @param _reward new boss reward
    /// @return bossId ID of the newly created boss; mainly to keep track of the level of the game
    function createBoss(uint256 _hp, uint256 _damage, uint256 _reward) external onlyAdmin returns (uint256) {
        if (bosses[bossId].status == BossStatus.Alive) revert BossAlreadyInGame();
        bossId++;
        boss = Boss(_hp, _damage, _reward, BossStatus.Alive);
        bosses[bossId] = boss;
        emit GameEvents.BossSpawned(bossId, boss);
        return bossId;
    }

    /// @notice Create a new semi random character. Only one character per address
    /// @return character the newly generated character
    function createCharacter() external returns (Character memory) {
        if (hasCharacterInGame[msg.sender]) revert CharacterAlreadyInGame();
        characters[msg.sender] = genCharacter();
        hasCharacterInGame[msg.sender] = true;
        emit GameEvents.CharacterCreated(msg.sender, characters[msg.sender]);
        return characters[msg.sender];
    }

    modifier needCharacter() {
        if (hasCharacterInGame[msg.sender] == false) revert NoCharacterInGame();
        _;
    }

    function attack() external needCharacter {
        if (boss.status == BossStatus.Unborn) {
            revert NoBossInGame();
        } else if (boss.status == BossStatus.Vainquished) {
            revert UnGentlemanLikeBehavior();
        } else if (boss.status == BossStatus.Alive) {
            if (characters[msg.sender].isDead()) revert CharacterIsDead();
            // the user attack the boss first because fantasy has taught us
            // a boss just wait for a player and dnever take the initiative
            boss = boss.takeDamages(characters[msg.sender].damage);
            emit GameEvents.HeroicFeat(msg.sender, bossId, characters[msg.sender].damage);
            // the boss counter-attack, dead or alive
            characters[msg.sender] = characters[msg.sender].takeDamages(boss.damage);
            emit GameEvents.Aaaaaaargh(bossId, msg.sender, boss.damage);
            // resolve post-attack state
            // when attackinga heror bcomees worthy
            rewards[msg.sender][bossId] = RewardStatus.Unclaimed;
            // a heor's death should be honored
            if (characters[msg.sender].isDead()) emit GameEvents.AHeroHasFallen(msg.sender);
            // a boss' death should be celebrated and their rewards become claimable
            if (boss.isDead()) emit GameEvents.BossVainquished(bossId);
        }
    }
}
