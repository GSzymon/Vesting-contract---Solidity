pragma solidity 0.8.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/token/ERC20/utils/SafeERC20.sol";

contract VestingModifiers {

    modifier ableToStartRelease (uint _currentStartDate, uint _newStartDate, uint _newEndDate, IERC20 _erc20) {
        require(_currentStartDate == 0, "Tokens release is already scheduled.");
        require(_newStartDate < _newEndDate, "EndDate cannot be lower than StartDate.");
        require(block.timestamp < _newStartDate, "StartDate cannot be lower than current timestamp.");
        require(_erc20.balanceOf(address(this)) > 0, "Unable to schedule release until there are no tokens on this contract.");
        _;
    }

    modifier releaseHasFinished (uint _startDate, uint _endDate) {
        require (_startDate != 0 && block.timestamp > _endDate, "Tokens release has not finished yet.");
        _;
    }

    modifier releaseHasStarted (uint _startDate, uint _endDate) {
        require (_startDate != 0 && block.timestamp > _startDate, "Tokens release has not started yet");
        _;
    }

    modifier releaseIsActive (uint _startDate, uint _endDate) {
        require (_startDate != 0 && block.timestamp > _startDate && block.timestamp < _endDate, "Tokens release is not active");
        _;
    }

    modifier hasAnyAllocation (uint _senderTotalAllocation) {
        require (_senderTotalAllocation > 0, "You are unable to claim any tokens.");
        _;
    }

    modifier requiresFee (uint _claimingFee) {
        require (msg.value >= _claimingFee, "It's not enough to pay claiming fee.");
        _;
    }  
}