//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

struct stakeInfo{
     uint64     rank;
    uint256     preShare;
    uint256     lastTimeStamp;
    uint256     amount;
    uint256     claimableReward;
}

interface  MYERC20  {
    function  MAX_SUPPLY() external view returns (uint);

}
contract KonkretStaking is ERC20, Ownable, ReentrancyGuard{
    mapping(address => stakeInfo) public stakeByOwner;
    address[] public stakers;
    uint public monthTimeStamp;
    IERC20 public immutable TOKEN_TO_STAKE;
    uint public immutable   TOKEN_TO_STAKE_MAX_SUPPLY;
    IERC20 immutable fakeDoll;
    address immutable treasury;





    event Staked(address who,uint amount , uint timeStamp);
    event unStaked(address who,uint amount , uint timeStamp);

    constructor(string memory protoSymbol, address _tokenToStake, address _currencyUsedToPay, address _treasury) ERC20("stakedKonkreteToken", protoSymbol) {
        TOKEN_TO_STAKE = IERC20(_tokenToStake);
        /// A changer
        TOKEN_TO_STAKE_MAX_SUPPLY = MYERC20(_tokenToStake).MAX_SUPPLY();
        fakeDoll = IERC20(_currencyUsedToPay);
        treasury = _treasury;

    }

    function _calculateShareratio(uint amount, uint lowTimestamp, uint lastTimeStamp) private pure returns(uint256 res){
        uint lol = amount * (lastTimeStamp - lowTimestamp);
        res = lol;
    }

    function beginTimestamp() external onlyOwner {
        monthTimeStamp = block.timestamp;
    }
    function stake(uint256 _amount) external nonReentrant {
        IERC20 tokenToStakeBuff = TOKEN_TO_STAKE;
        require(tokenToStakeBuff.allowance(msg.sender, address(this)) >= _amount, "Need to allow transfer first");
        require(tokenToStakeBuff.balanceOf(msg.sender) >= _amount, "Too much for balance");
        bool res = tokenToStakeBuff.transferFrom(msg.sender, address(this), _amount);
        require(res, "Transfer failed");
        stakeInfo memory infoBuffer = stakeByOwner[msg.sender];
        if (infoBuffer.rank == 0) {
            stakers.push(msg.sender);
            infoBuffer.rank = uint64(stakers.length);
        }
        uint256 newTimeStamp = uint256(block.timestamp);
        infoBuffer.preShare = _calculateShareratio(infoBuffer.amount, infoBuffer.lastTimeStamp, newTimeStamp);
        infoBuffer.lastTimeStamp = newTimeStamp;
        infoBuffer.amount += _amount;
        stakeByOwner[msg.sender] = infoBuffer;
        emit Staked(msg.sender, _amount, newTimeStamp);
    }

    function unStake(uint256 _amount) external nonReentrant {
        stakeInfo memory infoBuffer =  stakeByOwner[msg.sender];
        require(infoBuffer.amount >= _amount, "Can't unstake this much");
        uint256 newTimeStamp = uint256(block.timestamp);
        infoBuffer.preShare = _calculateShareratio(infoBuffer.amount, infoBuffer.lastTimeStamp, newTimeStamp);
        infoBuffer.lastTimeStamp = newTimeStamp;
        infoBuffer.amount -= _amount;
        TOKEN_TO_STAKE.transfer(msg.sender, _amount);
        stakeByOwner[msg.sender] = infoBuffer;
        emit unStaked(msg.sender , _amount, newTimeStamp);
    }
  
    function _getClaimableReward(uint256 newTimeStamp, stakeInfo memory _stakeInfo, uint256 denominator, uint256 _totalreward) private pure returns (stakeInfo memory) {
        _stakeInfo.claimableReward = _totalreward * (_stakeInfo.preShare + 
            _calculateShareratio(_stakeInfo.amount, _stakeInfo.lastTimeStamp,newTimeStamp )) / denominator;
        _stakeInfo.lastTimeStamp = newTimeStamp;
        _stakeInfo.preShare = 0;
        return(_stakeInfo);
    }
    function getStakeInfo(address tokenHolder) public view returns(stakeInfo memory) {
        return (
            (stakeByOwner[tokenHolder])
        );
    } 

    function setTotalClaimableReward(uint256 totalReward) external  nonReentrant {
        require(msg.sender == treasury, "Just Treasury");
        address[] memory stakersBuffer = stakers;
        uint256 newTimeStamp = block.timestamp;
        uint totalDenominator = (newTimeStamp - monthTimeStamp) * TOKEN_TO_STAKE_MAX_SUPPLY;
        for (uint i = 0; i < stakersBuffer.length ;){
            stakeByOwner[stakersBuffer[i]] = _getClaimableReward(newTimeStamp, stakeByOwner[stakersBuffer[i]], totalDenominator, totalReward);
            unchecked {++i;}
        }
        monthTimeStamp = newTimeStamp;
    }

    function claimReward() external nonReentrant {
        stakeInfo memory bufferStake = stakeByOwner[msg.sender];
        require(bufferStake.claimableReward > 0 , "Can't claim anything");
        fakeDoll.transferFrom(treasury, msg.sender, bufferStake.claimableReward);
        bufferStake.claimableReward = 0;
        stakeByOwner[msg.sender] = bufferStake;
    }
                                                                                             
}

