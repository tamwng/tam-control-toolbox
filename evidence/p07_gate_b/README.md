# P07 protected baseline

Tested source: `0ac937f94fbcc10c64742e9b4a47367e4d929cc1`, branch `v2-development`.
No scientific source was modified during these checks. This is a small
pre-refactor baseline, not a full-paper reproduction or independent confirmation.

- Recovery: 3,022 identical paths/files, 1,357,579,926 bytes, per-file SHA-256
  agreement before/after copying; both manifests have SHA-256
  `ba298a8a4c6132c28074c462e4bc19ed0911fa71bc366cfc3245dc46b5af94d6`.
- Recovery location: `C:\Users\Tam\Documents\EJC_P07_recovery_20260925`, outside
  the repository and OneDrive, on the same C: volume. It is not separate-device
  redundancy. Source archives were not moved, renamed or overwritten.
- Unchanged checks: 120 root tests and 17 P06 tests passed.
- Representatives: 12 P06 nominal gate cases (204 gate quantities), two Study 2
  cases, three Study 3 cases, three Study 4 cases, one Study 5 case. All underlying
  compared fits/trajectories/grid evaluations agreed exactly; wall-clock timing
  was excluded. Original P06 quantity-specific gate tolerances were unchanged.
- The first case harness stopped after 14 cases because historical Study 3
  settings contained an execution-description string. Every scientific setting
  agreed after separating that metadata. The original stopped attempt remains
  in `cases/status.json`; `CONFIGURATION_METADATA_EXCEPTION.md` documents the
  diagnosis. Only the seven not-yet-run cases were subsequently executed.
- A final archive rehash after all 21 cases found no changed protected files.

The CSVs, manifests, exact harnesses and logs here are compact review evidence.
The complete original execution evidence and representative MAT outputs remain
under `results/p07_gate_b_20260925/` and are intentionally not duplicated in Git.
Harnesses are retained as evidence; normal user commands are in the root README.
MATLAB temporary-folder cleanup warnings are retained in the logs; the checks
passed and the protected archives were unchanged. No warning was suppressed.

Historical source provenance is separate: P06 producing source is
`d1f1adb0d7891aba2a9555b7b7c73feb2897e7c7`. Producing revisions for Studies 1–6
remain unknown. Archive-introduction revisions do not fill that gap.
