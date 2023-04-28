//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/model/Boss.sol";

contract BossImplTest is Test {
    using BossImpl for Boss;

    function test_BossTakeDamagesAndLive(uint256 hp, uint256 damage) public {
        vm.assume(hp > damage);
        Boss memory boss = Boss(damage + 1, 0, 0, BossStatus.Alive);
        Boss memory damaged = boss.takeDamages(damage);
        assertEq(damaged.hp, boss.hp - damage);
        assert(damaged.status == BossStatus.Alive);
    }

    function test_BossTakeDamagesAndDie(uint256 hp, uint256 damage) public {
        vm.assume(hp <= damage);
        Boss memory boss = Boss(damage, 0, 0, BossStatus.Alive);
        Boss memory damaged = boss.takeDamages(damage);
        assertEq(damaged.hp, 0);
        assert(damaged.status == BossStatus.Vainquished);
    }

    function test_BossIsDead() public pure {
        Boss memory boss = Boss(0, 0, 0, BossStatus.Alive);
        assert(boss.isDead());
    }

    function test_BossIsNotDead() public pure {
        Boss memory boss = Boss(1, 0, 0, BossStatus.Alive);
        assert(!boss.isDead());
    }
}
