//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/model/Character.sol";

contract CharacterImplTest is Test {
    using CharacterImpl for Character;

    function testIfHPEqZero_CharacterIsDead(Character memory character) public pure {
        character.hp = 0;
        assert(character.isDead());
    }

    function test_IfHPPositive_CharacterIsNotDead(Character memory character, uint256 hp) public pure {
        vm.assume(hp > 0);
        character.hp = hp;
        assert(!character.isDead());
    }

    function test_IfCharacterAlive_CharacterCanFight(Character memory character, uint256 hp) public pure {
        vm.assume(hp > 0);
        character.hp = hp;
        assert(character.canFight());
    }

    function test_IfCharacterDead_CharacterCanNotFight(Character memory character) public pure {
        character.hp = 0;
        assert(!character.canFight());
    }

    function test_CharacterTakeDamagesAndCanStillFight(Character memory character, uint256 damage) public {
        vm.assume(character.hp > damage);
        Character memory damaged = character.takeDamages(damage);
        assertEq(damaged.hp, character.hp - damage);
        assert(damaged.canFight());
    }

    function test_CharacterTakeDamagesAndCanNotFight(Character memory character, uint256 damage) public {
        vm.assume(character.hp <= damage);
        Character memory damaged = character.takeDamages(damage);
        assertEq(damaged.hp, 0);
        assert(!damaged.canFight());
    }
}
