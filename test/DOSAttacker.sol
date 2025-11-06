// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {BriVault} from "../src/briVault.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DOSAttacker {
    BriVault public briVault;

    constructor(address _briVault) {
        briVault = BriVault(_briVault);
    }

    // function prepareAttack(uint256 _numberOfAddresses) public {
    //     for (uint256 i = 0; i < _numberOfAddresses; i++) {
            
    //     }
    // }

    // function attack() public {
    //     for (uint256 i = 0; i < _numberOfAddresses; i++) {
            
    //     }
    // }

}

contract DOSAttackerFactory {
    function createAttacker(address _briVault) public returns (address) {
        DOSAttacker attacker = new DOSAttacker(_briVault);
        return address(attacker);
    }
}



