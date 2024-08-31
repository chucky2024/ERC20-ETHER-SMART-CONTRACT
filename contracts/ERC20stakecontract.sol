// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Staking is Ownable {
    IERC20 public stakingToken;
    uint256 public rewardRatePerSecond; // Reward rate per second
    uint256 public minimumStakeDuration; // Minimum staking duration in seconds

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        bool exists;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);

    constructor(IERC20 _stakingToken, uint256 _rewardRatePerSecond, uint256 _minimumStakeDuration) {
        stakingToken = _stakingToken;
        rewardRatePerSecond = _rewardRatePerSecond;
        minimumStakeDuration = _minimumStakeDuration;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater than 0");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        Stake storage userStake = stakes[msg.sender];
        
        if (userStake.exists) {
            uint256 reward = calculateReward(msg.sender);
            require(stakingToken.transfer(msg.sender, reward), "Reward transfer failed");
        }

        userStake.amount = userStake.amount + _amount;
        userStake.timestamp = block.timestamp;
        userStake.exists = true;

        emit Staked(msg.sender, _amount);
    }

    function unstake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.exists, "No active stake found");
        require(block.timestamp >= userStake.timestamp + minimumStakeDuration, "Stake is still locked");

        uint256 amount = userStake.amount;
        uint256 reward = calculateReward(msg.sender);

        userStake.amount = 0;
        userStake.timestamp = 0;
        userStake.exists = false;

        require(stakingToken.transfer(msg.sender, amount), "Token transfer failed");
        require(stakingToken.transfer(msg.sender, reward), "Reward transfer failed");

        emit Unstaked(msg.sender, amount, reward);
    }

    function calculateReward(address _user) public view returns (uint256) {
        Stake storage userStake = stakes[_user];
        if (!userStake.exists) return 0;

        uint256 stakingDuration = block.timestamp - userStake.timestamp;
        if (stakingDuration < minimumStakeDuration) return 0;

        return (userStake.amount * rewardRatePerSecond * stakingDuration) / 1e18; // Reward calculation
    }

    function updateRewardRate(uint256 _newRate) external onlyOwner {
        rewardRatePerSecond = _newRate;
    }

    function updateMinimumStakeDuration(uint256 _newDuration) external onlyOwner {
        minimumStakeDuration = _newDuration;
    }
}
