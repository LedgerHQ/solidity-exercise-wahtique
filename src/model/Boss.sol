//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../utils/Math.sol";

enum BossStatus {
    Unborn,
    Alive,
    Vainquished
}

struct Boss {
    uint256 hp;
    uint256 damage;
    uint256 reward;
    BossStatus status;
}

library BossImpl {
    using Math for uint256;

    function takeDamages(Boss memory _boss, uint256 _damage) public pure returns (Boss memory updatedBoss) {
        _boss.hp = _boss.hp.flooredSubstract(_damage);
        if (_boss.hp == 0) {
            _boss.status = BossStatus.Vainquished;
        }
        updatedBoss = _boss;
    }

    function isDead(Boss memory _boss) public pure returns (bool) {
        return _boss.hp == 0;
    }
}
