//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/model/Character.sol";

contract CharacterImplTest is Test {
    using CharacterImpl for Character;

    Character bob;

    function setUp() public {
        bob = Character(100, 10, 10, 0, CharacterStatus.Alive);
    }

    function test_CharacterTakeDamagesAndCanStillFight(uint256 hp, uint256 damage) public {
        vm.assume(hp > damage);
        bob.hp = hp;
        Character memory damaged = bob.takeDamages(damage);
        assertEq(damaged.hp, bob.hp - damage);
        assert(damaged.status == CharacterStatus.Alive);
    }

    function test_CharacterTakeDamagesAndCanNotFight(uint256 hp, uint256 damage) public {
        vm.assume(hp <= damage);
        bob.hp = hp;
        Character memory damaged = bob.takeDamages(damage);
        assertEq(damaged.hp, 0);
        assert(damaged.status == CharacterStatus.Dead);
    }
}
