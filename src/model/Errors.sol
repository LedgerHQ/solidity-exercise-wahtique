//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

error CannotHealSelf();
error RewardAlreadyClaimed();
error YouAreUnworthy();

error SkillOnCooldown(string skill, uint256 cooldownEnd);
