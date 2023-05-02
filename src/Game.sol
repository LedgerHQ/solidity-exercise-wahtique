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

    /// @notice A character has healed another one
    /// @dev Emit this when a player heal another player
    /// @param healer the good guy
    /// @param target the lucky one
    /// @param amount blood debt
    event PositiveKarmaAction(address healer, address target, uint256 amount);

    /// @notice A dead character came back form the dead
    /// @dev Emit this when a playe is revived
    /// @param user address of the player who has been revived
    event WelcomeBack(address user);

    /// @notice A character has leveled up
    /// @dev Emit this when a player level up
    /// @param user address of the player who has leveled up
    /// @param level new level of the player
    event LevelUp(address user, uint256 level);
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

    /// @notice characters currently in the game ; only one character is allowed per address
    mapping(address user => Character character) public characters;

    /// @notice keep track of the status of past, current and future bosses
    mapping(uint256 bossId => Boss boss) public bosses;

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

    modifier requireCharacterStatus(CharacterStatus expected) {
        CharacterStatus actual = characters[msg.sender].status;
        if (actual != expected) revert WrongCharacterStatus(expected, actual);
        _;
    }

    modifier requireBossStatus(BossStatus expected) {
        BossStatus actual = boss.status;
        if (actual != expected) revert WrongBossStatus(expected, actual);
        _;
    }

    modifier requireLevel(uint256 level) {
        uint256 actual = characters[msg.sender].level;
        if (actual < level) revert LevelTooLow(level, actual);
        _;
    }

    /// @notice create a custom boss and add it to the game; need admin rights
    /// @dev increment bossId and add a new boss to the bosses mapping
    /// @param hp how much they can take
    /// @param damage how much they should hit back
    /// @param reward how much should be awarded to its murderers
    /// @return bossId like an IKEA shelf number, but for a boss
    /// @custom:emits GameEvents.BossSpawned It's aliiiiiiiiiiive !
    function createBoss(uint256 hp, uint256 damage, uint256 reward)
        external
        onlyAdmin
        requireBossStatus(BossStatus.Unborn)
        returns (uint256)
    {
        bossId++;
        boss = Boss(hp, damage, reward, BossStatus.Alive);
        bosses[bossId] = boss;
        emit GameEvents.BossSpawned(bossId, boss);
        return bossId;
    }

    /// @notice Create a new semi random character. Only one character per address
    /// @return character a peasant with a pitch-fork
    /// @custom:emits GameEvents.CharacterCreated Welcome to the world of Ledger !
    function createCharacter() external requireCharacterStatus(CharacterStatus.Unborn) returns (Character memory) {
        characters[msg.sender] = genCharacter();
        emit GameEvents.CharacterCreated(msg.sender, characters[msg.sender]);
        return characters[msg.sender];
    }

    /// @notice CHAAAAAARGE ( only if you have character who can fight)
    /// @custom:emits GameEvents.HeroicFeat the stuff of legends
    /// @custom:emits GameEvents.Aaaaaaargh self explanatory if you've ever been eviscerated
    /// @custom:emits GameEvents.AHeroHasFallen a moment of silence for the fallen
    /// @custom:emits GameEvents.BossVainquished VICTORY
    function attack() external requireCharacterStatus(CharacterStatus.Alive) requireBossStatus(BossStatus.Alive) {
        // the user attack the boss first because fantasy has taught us
        // a boss just wait for a player and dnever take the initiative
        boss = boss.takeDamages(characters[msg.sender].damage);
        emit GameEvents.HeroicFeat(msg.sender, bossId, characters[msg.sender].damage);
        // the boss counter-attack, dead or alive
        characters[msg.sender] = characters[msg.sender].takeDamages(boss.damage);
        emit GameEvents.Aaaaaaargh(bossId, msg.sender, boss.damage);
        // resolve post-attack state
        // when attacking a hero becomf=es worthy
        rewards[msg.sender][bossId] = RewardStatus.Unclaimed;
        // a hero's death should be honored
        if (characters[msg.sender].status == CharacterStatus.Dead) emit GameEvents.AHeroHasFallen(msg.sender);
        // a boss' death should be celebrated and their rewards become claimable
        if (boss.isDead()) emit GameEvents.BossVainquished(bossId);
    }

    /// @notice Heal another player for the player healing power.
    ///         Only if you have a character alive AND with some xp.
    /// @param other the one who will owe you a drink next time you go out ( ie. never )
    /// @custom:emits GameEvents.PositiveKarmaAction +1 for a heal
    /// @custom:emits GameEvents.WelcomeBack Valhalla can wait
    function heal(address other) external requireCharacterStatus(CharacterStatus.Alive) requireLevel(2) {
        if (other == msg.sender) revert CannotHealSelf();
        if (characters[other].status == CharacterStatus.Dead) emit GameEvents.WelcomeBack(other);
        characters[other] = characters[msg.sender].heal(characters[other]);
        emit GameEvents.PositiveKarmaAction(msg.sender, other, characters[msg.sender].healingPower);
    }

    /// @notice To the victorious goes the spoils
    /// @dev claim a reward if you are worthy and the boss is dead
    /// @param id the boss id
    /// @custom:emits GameEvents.BossRewardClaimed xp gained for the kill
    /// @custom:emits GameEvents.LevelUp Congratulations ! You can now start from zero again !
    function claimReward(uint256 id)
        external
        requireCharacterStatus(CharacterStatus.Alive)
        requireBossStatus(BossStatus.Vainquished)
    {
        if (rewards[msg.sender][id] == RewardStatus.Claimed) revert RewardAlreadyClaimed();
        if (rewards[msg.sender][id] == RewardStatus.Unworthy) revert YouAreUnworthy();
        characters[msg.sender] = characters[msg.sender].getXP(bosses[bossId].reward);
        rewards[msg.sender][bossId] = RewardStatus.Claimed;
        emit GameEvents.BossRewardClaimed(id, msg.sender, bosses[id].reward);
        if (characters[msg.sender].xp >= (characters[msg.sender].level + 1) * xpBase) {
            characters[msg.sender] = characters[msg.sender].levelUp();
            emit GameEvents.LevelUp(msg.sender, characters[msg.sender].level);
        }
    }
}
