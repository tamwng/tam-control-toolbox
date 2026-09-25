# Approved Study 1 legacy-schema compatibility

The first Gate C attempt tested candidate
`3b1b29e331022e7d48a7f5bf996f65d1d47b9e1b` from a clean source tree.
Its original output remains at `results/p07_local_20260925/`, including the
frozen manifest, full log, partial scientific outputs and post-stop hashes.
The attempt is superseded and remains `FAILED_OR_BLOCKED`; it is not relabeled
passed, resumed, or combined with a later candidate's results.

All 258 Study 1 trajectories and their diagnostics/summaries completed.
The comparison checked 535 files: 523 passed and 12 failed, solely because
two forecast evaluation flags were absent from each historical pilot file.
All common numerical values had maximum absolute difference zero, with no
nonfinite-mask mismatch. Studies 2–6 and P06 had not started in that attempt.
Its elapsed time was 747.3713206 seconds, excluding MATLAB startup.

The author explicitly approved the following rule and a new committed
candidate followed by a fresh full reproduction from the beginning:

- Only Study 1 `data/pilot_{A,K,P2,R,S,W}_{000,001}.mat` is eligible.
- Only absent historical `result.forecasts.identityChecksEvaluated` and
  `result.forecasts.firstStepCheckEvaluated` fields are eligible.
- Both fresh fields must exist and be logical scalars exactly equal to
  `isfinite(maxIdentityResidual)` and `isfinite(maxFirstStepFreezingError)`,
  respectively. These definitions are unchanged from the pre-P07 source.
- A flag already present historically still receives exact comparison.
- All other fields, paths, studies, values and tolerances retain exact
  comparison. No scientific source, record or solver setting changes.
- Each permitted omission is recorded explicitly. Missing historical flags
  do not prove that the historical execution evaluated those checks.

The comparator validates fresh flags before removing only an eligible missing
counterpart from its in-memory comparison. It never rewrites saved records.
Archive self-comparison remains distinct from fresh computation.

Compact copies below preserve the superseded attempt's original manifest,
24 failure rows, field-presence inspection, and post-stop integrity evidence.
The complete original comparison evidence remains in the original run tree.
All 3,022 protected files and all 213 candidate source files were unchanged
after that stop. Historical Study 1 producing provenance remains unknown.

All 17 comparator regression tests passed, including ten new legacy-schema
boundary checks. The compatibility-only recheck of the retained partial output
passed all 535 files with exactly 24 permitted omissions, maximum common
numerical difference zero, and all 3,022 protected checksums unchanged.
Results and the tested comparator/test-file SHA-256 values accompany this
record. Such a recheck validates the interface
correction; it is not the new fresh reproduction. The replacement candidate's
exact SHA is frozen in the new run's manifest after this checkpoint is committed.
Second-machine verification and final release remain pending.
