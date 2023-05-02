//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/model/Character.sol";

contract CharacterImplTest is Test {
    using CharacterImpl for Character;

    Character bob;

    function setUp() public {
        bob = Character(100, 10, 10, 0, 1, CharacterStatus.Alive);
    }

    function test_CharacterTakeDamagesAndCanStillFight(uint256 hp, uint256 damage) public {
        vm.assume(hp > damage);
        bob.hp = hp;
        Character memory damaged = bob.takeDamages(damage);
        assertEq(damaged.hp, bob.hp - damage);
        assert(damaged.status == CharacterStatus.Alive);
    }

    function test_CharacterTakeDamagesAndDie(uint256 hp, uint256 damage) public {
        vm.assume(hp <= damage);
        bob.hp = hp;
        Character memory damaged = bob.takeDamages(damage);
        assertEq(damaged.hp, 0);
        assert(damaged.status == CharacterStatus.Dead);
    }

    function test_Heal(uint256 heal, uint256 hp) public {
        vm.assume(hp > 0);
        vm.assume(heal > 0);
        vm.assume(hp < 1000);
        vm.assume(heal < 1000);
        bob.healingPower = heal;
        Character memory other = Character(hp, 0, 0, 0, 1, CharacterStatus.Alive);
        Character memory healed = bob.heal(other);
        assertEq(healed.hp, hp + heal);
    }

    function test_Revive(uint256 heal) public {
        vm.assume(heal > 0);
        bob.healingPower = heal;
        Character memory other = Character(0, 0, 0, 0, 1, CharacterStatus.Dead);
        Character memory healed = bob.heal(other);
        assertEq(healed.hp, heal);
        assert(healed.status == CharacterStatus.Alive);
    }
}
