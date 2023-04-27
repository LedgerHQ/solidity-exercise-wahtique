// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/utils/PseudoRandom.sol";

contract NumGenerator is PseudoRandom {
    function r(uint256 _max) public returns (uint256 _n) {
        _n = super.random(_max);
    }
}

contract PseudorandomTest is Test {
    uint256 constant MAX = 2 ** 256 - 1;

    NumGenerator public gen;

    function setUp() public {
        gen = new NumGenerator();
    }

    function test_RandomNumberLtMaxValue(uint256 _max) public {
        vm.assume(_max > 0);
        uint256 n = gen.r(_max);
        assertLt(n, _max);
    }

    function test_RandomNumberIsRandom() public {
        uint256 n1 = gen.r(MAX);
        uint256 n2 = gen.r(MAX);
        assert(n1 != n2);
    }

    function test_RevertIf_MaxIsZero() public {
        vm.expectRevert(ArithmeticError.selector);
        gen.r(0);
    }
}
