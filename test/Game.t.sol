// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "../src/model/Character.sol";
import "../src/model/Boss.sol";

abstract contract GameTest is Test {
    Game public game;

    function setUp() public {
        game = new Game();
    }
}

contract GameAdminTest is GameTest {
    function test_OwnerIsDeployer() public {
        assertEq(address(game.owner()), address(this));
    }

    function test_OwnerIsAdmin() public {
        assertEq(address(game.admin()), game.owner());
    }
}

contract GameBossTest is GameTest {
    function test_CreateBoss(uint256 _hp, uint256 _damage, uint256 _reward) public {
        uint256 bossId = game.createBoss(_hp, _damage, _reward);
        assertEq(bossId, 1);
    }

    function test_CreateBoss_EmitBossSpawned(uint256 _hp, uint256 _damage, uint256 _reward) public {
        vm.expectEmit();
        emit GameEvents.BossSpawned(1, Boss(_hp, _damage, _reward, BossStatus.Alive));
        game.createBoss(_hp, _damage, _reward);
    }

    function test_RevertWhen_CallAddBossWithoutAdminRights(
        address _notOwner,
        uint256 _hp,
        uint256 _damage,
        uint256 _reward
    ) public {
        vm.assume(address(game.admin()) != address(_notOwner));
        vm.expectRevert(Unauthorized.selector);
        vm.prank(address(_notOwner));
        game.createBoss(_hp, _damage, _reward);
    }
}

contract GameCharacterTest is GameTest {
    function test_CharactersAreUnbornByDefault(address user) public view {
        (,,,, CharacterStatus status) = game.characters(user);
        assert(status == CharacterStatus.Unborn);
    }

    function test_CreateCharacter() public {
        Character memory character = game.createCharacter();
        assertGt(character.hp, 0);
        assertGt(character.damage, 0);
        assertGt(character.healingPower, 0);
        assertEq(character.xp, 0);
    }

    function test_CreateCharacter_EmitCharacterCreated() public {
        vm.expectEmit(true, false, false, false);
        emit GameEvents.CharacterCreated(address(this), Character(100, 10, 10, 0, CharacterStatus.Alive));
        game.createCharacter();
    }

    function test_RevertWhen_CallCreateCharacterTwice() public {
        game.createCharacter();
        vm.expectRevert(CharacterAlreadyInGame.selector);
        game.createCharacter();
    }
}

contract GameFightTest is GameTest {
    function test_RevertIfCharacterIsUnborn() public {
        vm.expectRevert(UnbornCharacter.selector);
        game.attack();
    }

    function test_reverIfNoBossInGame() public {
        game.createCharacter();
        vm.expectRevert(NoBossInGame.selector);
        game.attack();
    }

    function test_RevertIfCharacterIsDead() public {
        // spawn Faker
        game.createBoss(1000000, 1000000, 0);
        // spawn a peasant
        Character memory bob = game.createCharacter();
        assertGt(bob.hp, 0);
        // bob attack Faker and get killed
        game.attack();
        (uint256 hp,,,,) = game.characters(address(this));
        assertEq(hp, 0);
        vm.expectRevert(CharacterIsDead.selector);
        game.attack();
    }

    function test_BossTakeDamages(uint256 _hp) public {
        // make sure the boss will survive
        vm.assume(_hp > game.characterBaseDamage() + game.characterBaseDamageDeviation());
        // spawn Faker
        game.createBoss(_hp, 0, 0);
        // spawn a peasant
        Character memory bob = game.createCharacter();
        assertGt(bob.hp, 0);
        // bob attack and the boss take damages
        game.attack();
        (uint256 hp,,,) = game.boss();
        assertEq(hp, _hp - bob.damage);
    }

    function test_BossTakeDamages_EmitHeroicFeat(uint256 _hp) public {
        vm.assume(_hp > 0);
        // spawn a boss
        game.createBoss(_hp, 0, 0);
        // spawn a peasant
        Character memory bob = game.createCharacter();
        // bob attack and the boss take damages
        vm.expectEmit();
        emit GameEvents.HeroicFeat(address(this), 1, bob.damage);
        game.attack();
    }

    function test_CharacterTakeDamages(uint256 _dmg) public {
        // make sure bob survives
        vm.assume(_dmg > 0);
        vm.assume(_dmg < game.characterBaseHealth() - game.characterBaseHealthDeviation());
        // spawn a boss to fight
        game.createBoss(1000, _dmg, 0);
        // spawn a peasant
        Character memory bob = game.createCharacter();
        uint256 expected = bob.hp - _dmg;
        assertGt(expected, 0);
        // bob attack and the boss take damages
        game.attack();
        (uint256 hp,,,,) = game.characters(address(this));
        assertEq(hp, expected);
    }

    function test_CharacterTakeDamages_EmitPainIndicator(uint256 _dmg) public {
        vm.assume(_dmg < game.characterBaseHealth() + game.characterBaseHealthDeviation());
        // spawn a boss to fight
        game.createBoss(1000, _dmg, 0);
        // spawn a peasant
        game.createCharacter();
        // bob attack and the boss take damages
        vm.expectEmit();
        emit GameEvents.Aaaaaaargh(1, address(this), _dmg);
        game.attack();
    }

    function test_BossSlaying(uint256 _hp) public {
        // make sure the boss will die
        vm.assume(_hp < game.characterBaseDamage() - game.characterBaseDamageDeviation());
        // spawn Faker
        game.createBoss(_hp, 0, 0);
        // spawn a peasant
        game.createCharacter();
        // bob attack and the boss is dead
        game.attack();
        (uint256 hp,,, BossStatus status) = game.boss();
        assertEq(hp, 0);
        assert(status == BossStatus.Vainquished);
    }

    function test_BossSlaying_EmitBossVainquished(uint256 _hp) public {
        vm.assume(_hp < game.characterBaseDamage() - game.characterBaseDamageDeviation());
        // spawn Faker
        game.createBoss(_hp, 0, 0);
        // spawn a peasant
        game.createCharacter();
        // bob attack and the boss is dead
        vm.expectEmit();
        emit GameEvents.BossVainquished(1);
        game.attack();
    }

    function test_HeroFalling(uint256 _dmg) public {
        // make sure bob will die
        vm.assume(_dmg > game.characterBaseHealth() + game.characterBaseHealthDeviation());
        // spawn a boss to fight
        game.createBoss(1000, _dmg, 0);
        // spawn a peasant
        game.createCharacter();
        // bob attack and dies like a noob
        game.attack();
        (uint256 hp,,,,) = game.characters(address(this));
        assertEq(hp, 0);
    }

    function test_HeroFalling_EmitEulogy(uint256 _dmg) public {
        // make sure bob will die
        vm.assume(_dmg > game.characterBaseHealth() + game.characterBaseHealthDeviation());
        // spawn a boss to fight
        game.createBoss(1000, _dmg, 0);
        // spawn a peasant
        game.createCharacter();
        // bob attack and dies like a noob
        vm.expectEmit();
        emit GameEvents.AHeroHasFallen(address(this));
        game.attack();
    }
}

contract GameHealTest is GameTest {
    function test_RevertIfSelfHealing() public {
        game.createCharacter();
        vm.expectRevert(CannotHealSelf.selector);
        game.heal(address(this));
    }

    function test_RevertIfCharacterIsUnborn(address other) public {
        vm.assume(other != address(this));
        // spawn somebody to heal
        vm.prank(other);
        game.createCharacter();
        // revert as this address has no character
        vm.expectRevert(UnbornCharacter.selector);
        game.heal(other);
    }

    function test_RevertIfCharacterIsDead(address other) public {
        vm.assume(other != address(this));
        // spawn somebody to heal
        vm.prank(other);
        game.createCharacter();
        // spawn a boss to kill the character
        game.createBoss(1000000, 1000000, 0);
        // kill the character
        game.createCharacter();
        game.attack();
        (uint256 hp,,,,) = game.characters(address(this));
        assertEq(hp, 0);
        // revert as this addres' character is dead
        vm.expectRevert(CharacterIsDead.selector);
        game.heal(other);
    }

    function test_RevertIfNotEnoughXp(address other) public {
        vm.assume(other != address(this));
        // spawn somebody to heal
        vm.prank(other);
        game.createCharacter();
        // create this address'char
        game.createCharacter();
        // revert as this addres' character does not have any xp
        vm.expectRevert(NotEnoughXP.selector);
        game.heal(other);
    }

    // todo test happy path once we have the reward system working
}
