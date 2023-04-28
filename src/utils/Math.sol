//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

library Math {
    function flooredSubstract(uint256 _a, uint256 _b) internal pure returns (uint256 _c) {
        if (_b > _a) {
            _c = 0;
        } else {
            _c = _a - _b;
        }
    }
}
