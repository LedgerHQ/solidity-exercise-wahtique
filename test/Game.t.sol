// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract GameTest is Test {
    Game public game;

    function setUp() public {
        game = new Game();
    }

    function test_OwnerIsDeployer() public {
        assertEq(address(game.owner()), address(this));
    }

    function test_OwnerIsAdmin() public {
        assertEq(address(game.admin()), game.owner());
    }

    function test_CreateBoss(uint256 _hp, uint256 _damage, uint256 _reward) public {
        uint256 bossId = game.createBoss(_hp, _damage, _reward);
        assertEq(bossId, 1);
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
