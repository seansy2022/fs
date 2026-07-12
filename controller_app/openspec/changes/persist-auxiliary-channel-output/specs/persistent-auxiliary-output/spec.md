## ADDED Requirements

### Requirement: CH3 and CH4 persist selected output
The system SHALL include the current CH3 and CH4 control state in every control heartbeat.

#### Scenario: Switch state persists
- **WHEN** a user changes a CH3 or CH4 switch state
- **THEN** every subsequent heartbeat SHALL contain the configured switch PWM value

### Requirement: Disabled auxiliary channel is safe
The system SHALL continuously output 1000 us for a disabled CH3 or CH4 channel.

#### Scenario: Disabled channel heartbeat
- **WHEN** CH3 or CH4 is disabled
- **THEN** its heartbeat output SHALL be 1000 us
