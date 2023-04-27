//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

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

struct Boss {
    uint256 hp;
    uint256 damage;
    uint256 reward;
}

struct Character {
    uint256 hp;
    uint256 damage;
    uint256 reward;
}

/// @title World of Ledger
/// @author William Veal Phan
contract Game is AdminRights {
    /// @notice owner of the contract
    /// @dev owner never changes
    address public immutable owner;

    /// @dev id of the last boss created; if eq 0, no boss exists
    uint256 bossId = 0;

    /// @notice bosses currently in the game
    mapping(uint256 => Boss) bosses;

    constructor() {
        // owner is the deployer of this contract
        owner = msg.sender;
        // owner inherit admin rights by default
        admin = msg.sender;
    }

    /// @notice create a custom boss and add it to the game; need admin rights
    /// @dev increment bossId and add a new boss to the bosses mapping
    /// @param _hp new boss starting hp
    /// @param _damage new boss damage
    /// @param _reward new boss reward
    /// @return bossId ID of the newly created boss
    function createBoss(uint256 _hp, uint256 _damage, uint256 _reward) external onlyAdmin returns (uint256) {
        bossId++;
        bosses[bossId] = Boss(_hp, _damage, _reward);
        return bossId;
    }
}
