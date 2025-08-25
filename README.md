# FitnessChain

A decentralized fitness training and achievement reward system that gamifies physical fitness and athletic performance on Stacks blockchain.

## Features

- Workout session management with exercise type and intensity tracking
- Performance-based reward system with fitness level bonuses
- Recovery period mechanics with time-based bonuses
- Fitness milestone achievements for advanced athletes
- Challenge participation system for competitive rewards
- Comprehensive fitness statistics and analytics

## Smart Contract Functions

### Public Functions
- `start-workout-session` - Begin workout session with exercise type and intensity
- `complete-workout-session` - Complete workout and earn rewards based on performance
- `claim-fitness-rewards` - Claim accumulated fitness tokens
- `start-recovery-period` - Begin recovery period for enhanced rewards
- `complete-recovery-period` - Complete recovery with time-based bonuses
- `achieve-fitness-milestone` - Achieve milestones for bonus rewards
- `participate-in-challenge` - Participate in challenges for competitive rewards

### Read-Only Functions
- `get-fitness-activity-count` - Get total fitness activities for user
- `get-fitness-token-balance` - Get current token balance
- `get-fitness-level` - Get current fitness level
- `get-achievement-count` - Get number of achievements unlocked
- `get-recovery-period` - Get current recovery period intensity
- `get-strength-progression` - Get strength progression bonus level
- `get-gym-stats` - Get platform-wide fitness statistics
- `calculate-workout-reward` - Calculate potential workout rewards

## Fitness Mechanics
- Exercise type affects workout time requirements
- Performance scores (0-100) provide bonus rewards
- Recovery periods add time-based reward multipliers
- Fitness milestones unlock at higher fitness levels
- Overtraining (early recovery completion) incurs penalties

## Usage

Deploy the contract to create a gamified fitness ecosystem where athletes can earn rewards for consistent training, achieving milestones, and participating in challenges.

## License

MIT