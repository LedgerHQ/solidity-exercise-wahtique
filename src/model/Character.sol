//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../utils/PseudoRandom.sol";
import "../utils/Math.sol";
import "./Errors.sol";

enum CharacterStatus {
    Unborn,
    Alive,
    Dead
}

struct Character {
    uint256 hp;
    uint256 damage;
    uint256 healingPower;
    uint256 xp;
    CharacterStatus status;
}

library CharacterImpl {
    using Math for uint256;

    function takeDamages(Character memory _character, uint256 _damage)
        public
        pure
        returns (Character memory updatedCharacter)
    {
        _character.hp = _character.hp.flooredSubstract(_damage);
        if (_character.hp == 0) {
            _character.status = CharacterStatus.Dead;
        }
        updatedCharacter = _character;
    }

    function heal(Character calldata healer, Character memory other) public pure returns (Character memory) {
        other.hp += healer.healingPower;
        other.status = CharacterStatus.Alive;
        return other;
    }
}

abstract contract CharacterOps is PseudoRandom {
    /// @notice base health of a character
    uint256 public characterBaseHealth = 100;
    /// @notice max health bonus of a character; a new character hp will be in [ base - dev, base + dev ]
    uint256 public characterBaseHealthDeviation = 10;
    /// @notice base damage of a character
    uint256 public characterBaseDamage = 10;
    /// @notice max damage bonus of a character; a new character damage will be in [ base - dev, base + dev ]
    uint256 public characterBaseDamageDeviation = 5;
    /// @notice base healing power of a character
    uint256 public characterBaseHealingPower = 10;
    /// @notice max healing power bonus of a character; a new character healing power will be in [ base - dev, base + dev ]
    uint256 public characterBaseHealingPowerDeviation = 5;

    function genCharacter() internal returns (Character memory) {
        uint256 hp = random(characterBaseHealth, characterBaseHealthDeviation);
        uint256 dmg = random(characterBaseDamage, characterBaseDamageDeviation);
        uint256 healingPower = random(characterBaseHealingPower, characterBaseHealingPowerDeviation);
        return Character(hp, dmg, healingPower, 0, CharacterStatus.Alive);
    }
}
