//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

/// @title World of Ledger
/// @author William Veal Phan
contract Game {
    /// @notice owner of the contract
    /// @dev owner never changes
    address public immutable owner;

    /// @notice address with admin permissions
    address public admin;

    constructor() {
        owner = msg.sender;
        admin = msg.sender;
    }
}
