//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 contract FakeDoll is ERC20 {
    constructor() ERC20("fakeUSD", "fUSD"){
        _mint(msg.sender, 20000*(10** 18));
    }

    function mint (uint _nb) external {
        _mint(msg.sender, _nb);
    }
}
