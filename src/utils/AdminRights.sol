//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

/// @notice error thrown when a function is called by without the appropriate rights
error Unauthorized();

/// @title Admin rights
/// @author William Veal Phan
/// @notice Define modifiers and functions to manage admin rights
/// @dev Inhirit from this contract and set admin address
contract AdminRights {
    /// @notice address with admin permissions
    address public admin;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }
}
