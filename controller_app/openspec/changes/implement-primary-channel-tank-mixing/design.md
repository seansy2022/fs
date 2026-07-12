## Context

CH1 throttle and CH2 steering currently map low, center, and high settings as percentages around 1500 us. Their values are sent directly by the control controller. Tank-mixing settings expose four UI directions but persist only two signed values and are not applied to control output.

The change spans persisted settings, settings UI, pure output mapping, the control controller, and tests. Source files must remain below the project line limits and non-UI logic requires unit coverage.

## Goals / Non-Goals

**Goals:**
- Give primary channels configurable 900..2100 us endpoint ranges through -120%..120% low/high settings.
- Treat the primary-channel center setting as a -100..100 us translation and constrain the translated curve to its configured endpoint range.
- Support forward, reverse, left-turn, and right-turn tank ratios independently.
- Keep ordinary control behavior unchanged while tank mixing is disabled.

**Non-Goals:**
- Change auxiliary-channel output semantics.
- Change receiver protocol framing, heartbeat cadence, failsafe storage, or Bluetooth behavior.
- Normalize both tracks together after mixing; each output is independently bounded.

## Decisions

### Primary-channel calibration uses a bounded translated curve

For CH1 and CH2, low/high percentages form the configured output range around 1500 us. Center is a direct microsecond offset. The low, center, and high points are translated by that offset, then independently clamped to the configured low/high endpoints.

This matches the required `-100 / 100 / 100 -> 1100 / 1600 / 2000` result. Treating center as another percentage would produce 2000 us at center=100 and is rejected.

### Tank mixing consumes calibrated PWM values

The mixer receives already-calibrated throttle and steering PWM values, their channel centers and boundaries, and the four ratio values. It does not access settings providers or UI state. The controller selects direct output when the feature is disabled and mixer output when enabled.

This keeps control math deterministic and allows all differential behaviors to be unit tested without widgets or BLE fakes.

### Differential direction convention is normalized

The mixer defines `turn = steeringCenter - steeringPwm`. Positive turn selects the left ratio; negative turn selects the right ratio. With scaled drive and turn contributions:

```
CH1 = ch1Center + drive + turn
CH2 = ch2Center + drive - turn
```

This unifies standalone and combined movement. It follows the supplied combination formulas; the contradictory standalone formulas are not used.

### Four ratios replace legacy signed values

Persist forward, reverse, left-turn, and right-turn values independently in the app settings state. Missing new fields default to 100. Legacy two-value settings cannot represent all four directions and are not inferred.

## Risks / Trade-offs

- [Existing non-zero primary center settings change semantic units] -> New persisted data uses the offset semantics; migration defaults continue to load safely and behavior is documented as breaking.
- [Mixed output can exceed a channel range] -> Clamp CH1 and CH2 independently to their configured endpoint ranges.
- [Direction wiring differs on a receiver] -> Existing channel reversal remains the calibration/wiring control; the mixer uses the normalized steering value.
- [Feature changes live output] -> Recalculate on every control sync and preserve disabled-mode direct output.

## Migration Plan

1. Add new four-ratio fields with defaults of 100 in model defaults and JSON parsing.
2. Ignore legacy `trackMixLeft` and `trackMixRight` when new fields are absent.
3. Update channel and tank-mixing UI bindings.
4. Deploy with unit and widget tests covering defaults, mapping, and mixed output.
5. Roll back by disabling tank mixing; ordinary channel output remains compatible.

## Open Questions

- The implementation assumes lower steering PWM means left turn. Hardware validation can invert the input through the existing channel reversal setting if required.
