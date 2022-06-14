//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PropertyToken is ERC20, Ownable {
    uint256 immutable public   MAX_SUPPLY;
    IERC20 immutable  kUSD;
    // uint public perTenThousand;
    event Buying(address buyer, uint amount);
    constructor(IERC20 _kUSD, uint _max_supply) ERC20("3 allee de l'epee, 78688 Voisin le Bretonneux", "3AdlE78VlB"){
        kUSD = _kUSD;
        require (_max_supply < 10000001 * (10 ** decimals()), "Above max appartement price");
        MAX_SUPPLY = _max_supply;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function buy(address _to, uint amount) external {
        IERC20 doll = kUSD;
        require(amount + totalSupply() <= MAX_SUPPLY , "Too much");
        require (doll.allowance(msg.sender, address(this)) >= amount, "Need to allow first");
        bool res = doll.transferFrom(msg.sender, owner() , amount);
        require(res, "Couldn't receive kUSD");
        _mint(_to, amount);
        emit Buying(_to, amount);
    }}
    








    




