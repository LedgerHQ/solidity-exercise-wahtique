// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract GameTest is Test {
    Game public game;

    function setUp() public {
        game = new Game();
    }

    function testOwner() public {
        assertEq(address(game.owner()), address(this));
    }

    function testAdmin() public {
        assertEq(address(game.admin()), game.owner());
    }
}
