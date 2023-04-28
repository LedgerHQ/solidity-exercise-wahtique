// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/utils/PseudoRandom.sol";
import "../../src/utils/Math.sol";

contract NumGenerator is PseudoRandom {
    function r(uint256 _max) public returns (uint256 _n) {
        _n = super.random(_max);
    }

    function r(uint256 _avg, uint256 _std) public returns (uint256 _n) {
        _n = super.random(_avg, _std);
    }
}

contract PseudorandomTest is Test {
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
        uint256 n1 = gen.r(Math.MAX_UINT256);
        uint256 n2 = gen.r(Math.MAX_UINT256);
        assert(n1 != n2);
    }

    function test_RevertIf_MaxIsZero() public {
        vm.expectRevert(ArithmeticError.selector);
        gen.r(0);
    }

    function test_RevertIf_StdGtAvg() public {
        vm.expectRevert(ArithmeticError.selector);
        gen.r(10, 11);
    }

    function test_RandomNumberWithAvgAndStdDev(uint256 _avg, uint256 _std) public {
        vm.assume(_std > 0);
        vm.assume(_avg > _std);
        // avoid underflow
        vm.assume(_avg < 100000000);
        uint256 n = gen.r(_avg, _std);
        assertLt(n, _avg + _std);
        assertGt(n, _avg - _std);
    }
}
