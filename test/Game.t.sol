// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "../src/model/Character.sol";
import "../src/model/Boss.sol";

contract GameTest is Test {
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
    function test_CreateCharacter() public {
        Character memory character = game.createCharacter();
        assertGt(character.hp, 0);
        assertGt(character.damage, 0);
        assertGt(character.healingPower, 0);
        assertEq(character.xp, 0);
    }

    function test_CreateCharacter_EmitCharacterCreated() public {
        vm.expectEmit(true, false, false, false);
        emit GameEvents.CharacterCreated(address(this), Character(100, 10, 10, 0));
        game.createCharacter();
    }

    function test_RevertWhen_CallCreateCharacterTwice() public {
        game.createCharacter();
        vm.expectRevert(CharacterAlreadyInGame.selector);
        game.createCharacter();
    }
}
