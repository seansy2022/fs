## Why

CH1 and CH2 currently interpret all three channel settings as percentage-based PWM points, which cannot express the required center offset behavior. The existing tank mixing screen also stores only two values and the control path does not perform differential track mixing.

## What Changes

- Add primary-channel calibration with `-120%..120%` low/high endpoints and a `-100..100 us` center offset for CH1 and CH2.
- Add four independently persisted tank-mixing ratios for forward, reverse, left turn, and right turn, all defaulting to `100%`.
- Apply differential CH1/CH2 mixing only when tank mixing is enabled, using the calibrated PWM values and per-channel boundaries.
- **BREAKING**: Existing non-zero primary-channel center settings change from percentage semantics to microsecond-offset semantics.
- **BREAKING**: Legacy two-value tank-mixing settings are replaced by four ratios; absent new values initialize to `100%`.

## Capabilities

### New Capabilities
- `primary-channel-calibration`: Calibrates CH1 throttle and CH2 steering ranges with bounded center offsets.
- `differential-tank-mixing`: Produces safe CH1/CH2 differential outputs from calibrated throttle and steering values.

### Modified Capabilities
- None.

## Impact

- `lib/src/features/settings/models/app_settings_state.dart`
- Channel settings, tank-mixing settings, and control output controllers
- Primary-channel mapping and new tank-mixing unit tests
- `File.md` file-organization inventory
