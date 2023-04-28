//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

error ArithmeticError();

/// @title Pseudo Random number generator
/// @author William Veal Phan
/// @notice Generate pseudo random numbers
/// @dev Inherit this contract to use the pseudo random number generator
abstract contract PseudoRandom {
    uint256 seed = 0;

    /// @notice Generate a pseudo random number
    /// @param _max The maximum value of the pseudo random number
    /// @return _n pseudo random number between 0 and _max
    function random(uint256 _max) internal returns (uint256 _n) {
        if (_max <= 0) revert ArithmeticError();
        seed++;
        _n = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % _max;
    }

    function random(uint256 _avg, uint256 _std) internal returns (uint256 _n) {
        if (_std > _avg) revert ArithmeticError();
        _n = _avg + random(_std) - random(_std);
    }
}
