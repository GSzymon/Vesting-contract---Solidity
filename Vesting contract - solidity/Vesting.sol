pragma solidity 0.8.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b3b83b558ebb9982e27ae5ee0bb5f33f278863dd/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/math/SafeMath.sol";
import "./VestingModifiers.sol";
import "./VestingEvents.sol";

contract Vesting is Ownable, VestingModifiers, VestingEvents {

    using SafeMath for uint;

    struct Allocation {
        uint totalAllocation;
        uint withdrawnTokensAmount;
    }

    mapping (address => Allocation) public allocations;
    uint public startDate;
    uint  public endDate;
    address payable public feesReceiver;
    uint public fee;
    IERC20 public erc20;
    uint public initialTokensReleasePercent = 10;
    uint public totalAllocatedTokens;

    function scheduleLinearRelease(uint _startDate, uint _endDate, IERC20 _erc20, address _feesReceiver) external onlyOwner ableToStartRelease(startDate, _startDate, _endDate, _erc20) {
        startDate = _startDate;
        endDate = _endDate;
        erc20 = _erc20;
        feesReceiver = payable(_feesReceiver);

        emit TokensReleaseScheduled(msg.sender, _erc20, _startDate, _endDate);
    }

    function claimTokens() external payable requiresFee(fee) releaseHasStarted(startDate, endDate) hasAnyAllocation(allocations[msg.sender].totalAllocation) {
        uint balanceAbleToClaim = calculateAvailableTokensToClaim();
        feesReceiver.transfer(fee);

        uint contractBalance = erc20.balanceOf(address(this));
        require(contractBalance >= balanceAbleToClaim, "There is no such number of tokens available on this contract.");      

        allocations[msg.sender].withdrawnTokensAmount = balanceAbleToClaim.add(allocations[msg.sender].withdrawnTokensAmount);
        totalAllocatedTokens = totalAllocatedTokens.sub(balanceAbleToClaim);
        erc20.transfer(msg.sender, balanceAbleToClaim);
    }

    function withdrawNotCollectedTokens (address _receiver) external onlyOwner releaseHasFinished(startDate, endDate) {
        uint balance = erc20.balanceOf(address(this));
        erc20.transfer(_receiver, balance);
        emit ContractOwnerWithdrawnRemainingTokens(_receiver, balance);
    }

    function setFeesReceiver(address payable _feesReceiver) external onlyOwner {
        feesReceiver = _feesReceiver;
        emit FeeReceiverUpdated(feesReceiver);
    }

    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
        emit FeeUpdated(fee);
    }

    function registerParticipant(address _address, uint _allocation) external onlyOwner {
        uint contractAvailableBalance = erc20.balanceOf(address(this)).sub(totalAllocatedTokens);
        
        if(allocations[_address].totalAllocation != 0) {
            uint notCollectedTokensAmountByParticipant = allocations[_address].totalAllocation.sub(allocations[_address].withdrawnTokensAmount);
            totalAllocatedTokens = totalAllocatedTokens.sub(notCollectedTokensAmountByParticipant);
            contractAvailableBalance = contractAvailableBalance.add(notCollectedTokensAmountByParticipant);
        }

        require(contractAvailableBalance >= _allocation, "There is no such number of tokens available on this contract.");
        allocations[_address].totalAllocation = _allocation;
        allocations[_address].withdrawnTokensAmount = 0;

        totalAllocatedTokens = totalAllocatedTokens.add(_allocation);
        emit ParticipantAllocationUpdated(msg.sender, _allocation);
    }

    function showMyVestingDetails() external hasAnyAllocation(allocations[msg.sender].totalAllocation){
        emit ShowParticipantDetails(calculateAvailableTokensToClaim(), allocations[msg.sender].totalAllocation, allocations[msg.sender].withdrawnTokensAmount);
    }

    function calculateAvailableTokensToClaim() private view returns(uint) {

        if(allocations[msg.sender].totalAllocation == 0) {
            return 0;
        }
        if(startDate > block.timestamp) {
            return 0;
        }
        if(block.timestamp > endDate) {
            return allocations[msg.sender].totalAllocation.sub(allocations[msg.sender].withdrawnTokensAmount);
        }

        uint percentOfTotalUnlockedCoins = initialTokensReleasePercent;
        percentOfTotalUnlockedCoins += ((block.timestamp - startDate) *(100-initialTokensReleasePercent)) / (endDate - startDate);

        return (allocations[msg.sender].totalAllocation.div(100).mul(percentOfTotalUnlockedCoins)).sub(allocations[msg.sender].withdrawnTokensAmount);
    }
}