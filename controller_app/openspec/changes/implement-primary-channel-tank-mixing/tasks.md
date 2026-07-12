## 1. Settings Model and Calibration

- [x] 1.1 Add four persisted tank ratio fields with safe JSON defaults and update settings controller APIs.
- [x] 1.2 Update primary-channel input constraints and UI semantics for extended endpoints and center offsets.
- [x] 1.3 Implement bounded primary-channel calibration results and unit tests.

## 2. Differential Mixing

- [x] 2.1 Add a pure tank-mixing calculator with independent CH1 and CH2 bounds.
- [x] 2.2 Add unit tests for individual actions, combined actions, ratios, and bounds.
- [x] 2.3 Integrate calibrated direct or mixed output into the control controller.

## 3. Settings UI and Verification

- [x] 3.1 Bind the tank-mixing page's four controls to the independent ratio fields.
- [x] 3.2 Update widget tests and settings serialization tests for the new defaults and interactions.
- [x] 3.3 Update File.md, run targeted tests and static analysis, and review the final diff.
