// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract StakeEther {

    struct StakesInfo {
        uint256 stakedAmount;
        address owner;
        uint256 duration; // Duration in seconds
        uint256 endStakingTime;
        bool isClosed;
    }

    // Mapping to store user deposits
    mapping(address => uint256) public deposits;
    // Mapping to store user stakes
    mapping(address => StakesInfo) public userStakes;

    uint256 public annualInterestRate; // Fixed interest rate

    event Deposited(address indexed owner, uint256 amount);
    event Staked(address indexed owner, uint256 amount, uint256 duration);
    event Withdrawn(address indexed owner, uint256 amount, uint256 reward);

    constructor(uint256 _fixedInterestRate) {
        annualInterestRate = _fixedInterestRate; // Set fixed rate
    }

    // Function to deposit Ether into the contract
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        deposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Function to stake Ether
    function stakingEthers(uint256 _amount, uint256 _duration) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(deposits[msg.sender] >= _amount, "Insufficient deposit balance");
        require(_amount > 0, "Insufficient deposit balance for staking");

        StakesInfo storage existingStake = userStakes[msg.sender];
        require(existingStake.isClosed || existingStake.stakedAmount == 0, "Existing stake is still active!");

        uint256 endStakingTime = block.timestamp + _duration;

        // Update the staked amount
        userStakes[msg.sender] = StakesInfo({
            stakedAmount: _amount,
            owner: msg.sender,
            duration: _duration,
            endStakingTime: endStakingTime,
            isClosed: false
        });

        // Deduct staked amount from deposits
        deposits[msg.sender] -= _amount;

        emit Staked(msg.sender, _amount, _duration);
    }

    // Function to withdraw the staked amount and rewards
    function withdraw() external {
        StakesInfo storage stake = userStakes[msg.sender];
        require(block.timestamp >= stake.endStakingTime, "Staking period has not ended");
        require(!stake.isClosed, "Stake already withdrawn");

        uint256 principal = stake.stakedAmount;
        uint256 interest = calculateInterest(principal, stake.duration);
        uint256 totalAmount = principal + interest;

        stake.isClosed = true;
        stake.stakedAmount = 0; // Prevent re-entrancy attacks

        payable(msg.sender).transfer(totalAmount);

        emit Withdrawn(msg.sender, principal, interest);
    }

    // Internal function to calculate interest based on the staking duration
    function calculateInterest(uint256 principal, uint256 duration) internal view returns (uint256) {
        uint256 timeInYears = duration / (365 * 24 * 60 * 60);
        uint256 interest = (principal * annualInterestRate * timeInYears) / 100;
        return interest;
    }
}
