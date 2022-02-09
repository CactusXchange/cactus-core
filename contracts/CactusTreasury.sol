//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICactusToken.sol";

contract CactusTreasury is Ownable {
    ICactusToken public cactt;

    constructor(ICactusToken _cactt) {
        cactt = _cactt;
    }

    function balance() public view returns (uint256) {
        return cactt.balanceOf(address(this));
    }

    function burn(uint256 amount) public onlyOwner {
        cactt.burn(address(this), amount);
    }

    function setCACTT(ICactusToken _newCactt) public onlyOwner {
        cactt = _newCactt;
    }
}
