pragma solidity 0.8.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/token/ERC20/utils/SafeERC20.sol";

contract VestingEvents {
    event TokensReleaseScheduled(address owner, IERC20 erc20, uint startDate, uint endDate);
    event ParticipantAllocationUpdated(address participantAddress, uint allocation);
    event ShowParticipantDetails(uint ableToClaimAmount, uint totalAllocation, uint withdrawnAmount);
    event FeeUpdated(uint fee);
    event FeeReceiverUpdated(address receiver);
    event ContractOwnerWithdrawnRemainingTokens(address receiver, uint amount);
}