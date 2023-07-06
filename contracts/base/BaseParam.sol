// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseParam{
    
    uint immutable _baseDecimals = 1e13;
    uint immutable _baseProportion = 10000;

    struct BInfo {
        uint baseDecimals;
        uint baseProportion;
    }

    function getBaseParam() external pure returns (BInfo memory) {
        return BInfo(_baseDecimals, _baseProportion);
    }

}