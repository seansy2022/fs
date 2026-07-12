## ADDED Requirements

### Requirement: Disabled tank mixing preserves direct controls
The system SHALL send calibrated throttle and steering values directly when tank mixing is disabled.

#### Scenario: Tank mixing disabled
- **WHEN** the user controls the vehicle while tank mixing is disabled
- **THEN** CH1 SHALL use throttle output and CH2 SHALL use steering output without differential mixing

### Requirement: Tank mixing supports four independent ratios
The system SHALL persist forward, reverse, left-turn, and right-turn ratios independently with defaults of 100%.

#### Scenario: New settings use default ratios
- **WHEN** a settings record lacks the four tank ratio fields
- **THEN** the system SHALL use 100% for all four ratios

### Requirement: Tank mixing computes differential outputs
The system SHALL use calibrated PWM values and their channel centers to calculate scaled drive and turn contributions when tank mixing is enabled.

#### Scenario: Forward left turn
- **WHEN** throttle is above its center, steering is below its center, forward ratio is 100%, and left ratio is 50%
- **THEN** CH1 SHALL contain the drive contribution plus half the left-turn contribution and CH2 SHALL contain the drive contribution minus half the left-turn contribution

### Requirement: Tank outputs are channel-bounded
The system SHALL clamp each mixed track output to its own calibrated channel range.

#### Scenario: CH1 reaches its high bound
- **WHEN** a mixed CH1 value exceeds CH1's configured high endpoint
- **THEN** CH1 SHALL equal its configured high endpoint while CH2 SHALL retain its independently bounded output
