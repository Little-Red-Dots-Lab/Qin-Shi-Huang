// SPDX-License-Identifier: MIT
// Creator: Little Red Dots Laboratory

pragma solidity ^0.8.18;

import {Strings} from "../script/lib/Strings.sol";
import {ERC20C} from "./riclic/ERC20C_v0.1.sol";

contract Emperor is ERC20C {
    // =============================================================
    //                           STORAGE
    // =============================================================
    // Maximum token amount of reward.
    uint256 internal _reward;

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================
    /**
     * Token name is "Qin Shi Huang ~ First Emperor of Qin Dynasty";
     * Token symbol is "QSH";
     * Total supply is 1e27;
     * Locked reward is 1e26;
     * Fair launch price is 1e-5 ether;
     * Fair launch limit (maximum token amount for one account during fair launch) is 1e24;
     * Account limit (maximum token amount for one account after fair launch before reward is unlocked) is 2 * 1e24;
     * 
     * Fair launch amount is 4.5 * 1e26;
     * ETH liquidity is 4500 BNB;
     * Token liquidity is 4.5 * 1e26;
     */
    constructor() ERC20C("Qin Shi Huang ~ First Emperor of Qin Dynasty", "QSH", 1e27, 1e26, 1e-5 ether, 1e24, 2 * 1e24) {
        _reward = _lockedReward;
    }

    // =============================================================
    //                  REWARD UNLOCK FUNCTIONS
    // =============================================================
    /**
     * 45% of total tokens are reserved for fair launch;
     * 45% of total tokens are reserved for liquidity;
     * 10% of total tokens are reserved for reward, to be unlocked in 10 phases:
     *   when token price reaches 10 times of fair launch price, release first 1%;
     *   when token price reaches 20 times of fair launch price, release 1%;
     *   when token price reaches 30 times of fair launch price, release 1%;
     *   when token price reaches 40 times of fair launch price, release 1%;
     *   when token price reaches 50 times of fair launch price, release 1%;
     *   when token price reaches 60 times of fair launch price, release 1%;
     *   when token price reaches 70 times of fair launch price, release 1%;
     *   when token price reaches 80 times of fair launch price, release 1%;
     *   when token price reaches 90 times of fair launch price, release 1%;
     *   when token price reaches 100 times of fair launch price, release final 1%;
     */
     function _unlock(uint256 multiplier) internal override {
        if (_lockedReward == 0) {
            return;
        }

        uint256 lockAmount = 0;
        if (multiplier < 100) {
            lockAmount = _reward * (10 - multiplier / 10) / 10;
        }

        uint256 unlockAmount = (_lockedReward > lockAmount) ? (_lockedReward - lockAmount) : 0;

        if (unlockAmount > 0) {
            // Remove _accountLimit if not 0.
            if (_accountLimit != 0) {
                _accountLimit = 0;
            }
            _transfer(address(this), owner(), unlockAmount);
            _lockedReward = lockAmount;
        }
    }
}
