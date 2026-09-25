# P07 Gate B: pre-refactor baseline

Approved source: `0ac937f94fbcc10c64742e9b4a47367e4d929cc1`, branch `v2-development`.
All scientific source is unchanged. Files in this new evidence directory are orchestration and verification records, not historical results.

Recovery is verified at `C:\Users\Tam\Documents\EJC_P07_recovery_20260925`: 3,022 protected files, 1,357,579,926 bytes. Relative paths and all SHA-256 values match; originals were rehashed unchanged. The copy is outside the repository and OneDrive tree, on the same C: volume. It is not separate-device redundancy. The protected set is the fixed manifest, not newly generated P07 directories.

## Execution safety

The unchanged root test suite writes only isolated TemporaryFolderFixture data. P06 tests require a new output directory and copy their two reference cases before exercising summaries. Direct fit, trajectory and P06 gate functions do not write files. Historical summarizers, full study runners and plotting are excluded from this baseline. MATLAB temporary files and logs are directed into this new evidence directory. No automatic retries are permitted.

## Checks and fixed representative cases

1. Existing `run_verification` and separately `run_p06_tests`.
2. The existing twelve nominal P06 gate cases: all six models, trials 0 and 1.
3. Study 2 exact-sine amplitude 1.0 and known-model constraint audit.
4. Study 3 shared variable-rate forgetting: abrupt trials 0 and 1; drift trial 0.
5. Study 4 augmented affine model: all three prescribed scenarios.
6. Study 5 integrated physical model and existing physical unit checks.

The representatives are full cases at the original settings. No durations, inputs, priors, seeds, solvers or tolerances are changed. Fits are recomputed from preserved input/noise records, not loaded as new fitted answers.

## Comparison rules fixed before execution

Configurations, record identities, arrays, indexing, counts, applicability and nonfinite masks must agree exactly. The P06 gate retains its existing quantity-specific absolute/relative tolerances: fitted theta/beta/covariance and initialization prediction 1e-10/1e-10; trajectory x/y/u/theta/prediction 1e-7/1e-7; whole-run scores 1e-8/1e-7. Statuses and acceptance flags are exact. Report exact equality as well as the existing gate outcome.

For the additional same-environment representatives, require exact agreement of deterministic numeric and discrete fit/trajectory quantities with the retained reference. Wall-clock `controlTime` is measured and reported separately, never compared for equality. No performance ordering is a correctness assertion. Any mismatch is preserved and stops Gate B for review; no tolerance will be inferred from its magnitude. Existing mathematical/solver checks keep their own original thresholds.

Record maximum discrepancies and locations, including any zero maxima. Refactoring starts only after all applicable baseline checks pass. This stage does not establish full-paper or second-machine reproduction.
