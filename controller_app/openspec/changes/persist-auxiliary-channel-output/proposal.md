## Why

CH3 and CH4 button changes are currently queued as one-shot pulses, so their selected state is not retained in later control heartbeats.

## What Changes

- Persist CH3 and CH4 control-page outputs in the base heartbeat frame.
- Define disabled CH3/CH4 output as 1000 us.

## Capabilities

### New Capabilities
- `persistent-auxiliary-output`: Continuously sends the selected CH3/CH4 control value.

### Modified Capabilities
- None.

## Impact

- Control controller and unit tests.
