## ADDED Requirements

### Requirement: Primary channel endpoint calibration
The system SHALL map CH1 and CH2 low and high settings from -120%..120% to endpoint values around 1500 us, allowing a 900..2100 us configured range.

#### Scenario: Extended endpoint range
- **WHEN** a primary channel uses low=-120% and high=120%
- **THEN** its configured endpoints SHALL be 900 us and 2100 us

### Requirement: Primary channel center offset
The system SHALL treat the CH1 and CH2 center setting as a direct -100..100 us curve translation and SHALL constrain translated points to the configured channel endpoints.

#### Scenario: Positive center translation at default endpoints
- **WHEN** a primary channel uses low=-100%, center=100, and high=100%
- **THEN** its low, center, and high output points SHALL be 1100 us, 1600 us, and 2000 us

### Requirement: Independent primary-channel boundaries
The system SHALL apply CH1 and CH2 calibration and output bounds independently.

#### Scenario: Distinct channel ranges
- **WHEN** CH1 and CH2 have different low, center, or high settings
- **THEN** each channel SHALL use its own mapped center and endpoint bounds
