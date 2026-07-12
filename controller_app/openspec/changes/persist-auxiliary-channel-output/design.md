## Context

The control buffer repeats base values every heartbeat but auxiliary buttons currently enqueue a single overriding frame.

## Goals / Non-Goals

**Goals:** Persist CH3/CH4 disabled, switch, multi-state, and fixed-value outputs.

**Non-Goals:** Change BLE framing, heartbeat cadence, or CH5+ behavior.

## Decisions

Auxiliary button presses update runtime state and call the normal base-output sync. Disabled maps directly to 1000 us; all other types use their configured current value.

## Risks / Trade-offs

- [Old callers expect a pulse] -> CH3/CH4 intentionally change to sustained outputs; other queued pulse support remains available.
