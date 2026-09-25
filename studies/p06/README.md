# P06 sensitivity reproduction

P06 is the frozen paper's seven-setting Study 1 sensitivity study (Table A.18). Its historical execution completed all 1,558 cases at source `d1f1adb0d7891aba2a9555b7b7c73feb2897e7c7`; the records are under `results/p06_sensitivity_20260924_225708/`. P08 is closed, and these results remain exploratory numerical evidence. Reused Study 1 records do not establish independent confirmation.

From the repository root, the P07 public entry point is `run_ejc('p06')`. See the root README for current command-verification status. The original entry points remain available:

```matlab
addpath('studies/p06');
run_p06('results/new_p06_plan');
run_p06_tests('results/new_p06_tests');
run_p06('results/new_p06_run','execute','P06_PRODUCTION_AUTHORIZED');
```

Each destination must be new. The default `run_p06` mode writes only the manifest: it reads saved records/settings and hashes source files, without fitting, propagation, QP solution or bootstrap. Local tests use synthetic observations and copies of saved cases. The explicit execution mode is the expensive campaign; its token distinguishes it from a dry run.

## Fixed computation

There are 38 distinct configuration/model combinations: five adaptive models at seven OFAT settings and the known-model reference at three input weights. Each has one deterministic and 40 paired noisy cases, totalling 1,558. The first 12 nominal cases (six models, trials 0 and 1) are included in that total; a baseline mismatch stops the remaining campaign. Known-model prior/length variants are aliases, not additional observations.

The records are `results/study1_candidate_20260917/data/records_confirmation.mat`. The historical directory/campaign labels stay unchanged. Input/evaluation seeds are 2101/2102; initialization/control measurement noise uses 2200+j/2300+j. The saved arrays are reused without regeneration. The first 50/100/200 fitting transitions retain their original endpoint indexing; control noise always starts at its first sample.

Each adaptive case fits afresh from its selected prefix and normalized prior; there is no fit cache. Both fitted coefficients and covariance pass into control. Scaling stays on the original calibration grid. R changes only in the QP. `study1_fit`'s optional positive fourth argument scales the normalized prior; omitted/1 preserves baseline arithmetic. `study1_summarize('p06_helpers')` exposes the existing scoring helpers without changing their ordinary path.

Whole-run metrics use [0,120); applied increments use k=1:1199 and exclude the unused terminal input. A held-out prediction score requires all 600 queries. Partial-run rows retain their status; complete-run scores are NaN for incomplete control. Raw Gram `cond(G)` remains distinct from corrected numerical rank. No recovery metric or extra forecast campaign is added.

Paired bootstrap uses mt19937ar/7401 and 2,000 resamples, separate from experimental streams. Configuration/model/trial order is fixed. Initial, pre-contrast and final states are saved. Intervals are contrast-specific. See `p06_schema.m` and the historical execution report for the exact table definitions.

## Comparison and provenance

The existing nominal gate requires exact statuses, counts, update/control acceptance and nonfinite masks. Fitted theta/beta/covariance and initialization prediction use `atol=rtol=1e-10`; trajectory x/y/u/theta/prediction use `atol=rtol=1e-7`; whole-run scores use `atol=1e-8, rtol=1e-7`. These predeclared comparison tolerances are not historical solver settings. They must not be changed after a discrepancy. Timing and machine-dependent condition estimates are separate diagnostics.

The historical execution passed all 204 gate comparisons with zero maximum discrepancy, completed in 3,865.9445834 s on the recorded Windows/R2026a machine, and retained all attempts. This does not establish a new P07 run or second-machine agreement.

The pre-interface fixture was captured at `05000a19bad01e52d852e1d63ac21f607d7596ae`. It holds short synthetic fits and old summarizer outputs from two copied Shared cases; it is protected evidence, not a newly generated plant trajectory.

`p06_provenance` reports the current invocation's commit, source hashes, environment and actual solver options. `productionLaunched` belongs only to that invocation. Historical source gaps remain UNKNOWN. Its P06/P07/P08 metadata distinguishes completed historical P06 evidence, pending release verification and closed exploratory P08 status. Historical snapshots/reports retain their original wording unchanged.
