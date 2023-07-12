// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract AirDorpEMB {

    function ariDorp(address[] calldata addrs) external payable {
        for (uint i; i < addrs.length; i++) {
            payable(addrs[i]).transfer(1e17);
        }
        if (msg.value > (addrs.length * 1e17)) {
            payable(msg.sender).transfer(msg.value - (addrs.length * 1e17));
        }
    }

}

