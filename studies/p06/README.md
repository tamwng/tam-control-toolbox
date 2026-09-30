# Sensitivity to tuning and initialization

The seven-setting paired sensitivity study varies input weight, normalized prior and fitting-record length, one factor at a time. It remains exploratory numerical evidence, not independent confirmation.

From the repository root:

```matlab
run_sensitivity('plan');
run_sensitivity('case',Case='baseline_S_000',OutputDirectory='nominal_case');
% Expensive: 1,558 cases, not a small example.
run_sensitivity('all',OutputDirectory='sensitivity_run',ConfirmFull=true);
```

Each destination must be new. Planning writes the fixed design and status without fitting, simulation or historical input. A named case runs exactly that existing selection. Generation saves result/scores/item/failure records, then applies internal checks. Reference agreement is not requested or implied by generation.

## Fixed computation

There are 38 distinct configuration/model combinations: five adaptive models at seven OFAT settings and the known-model reference at three input weights. Each has one deterministic and 40 paired noisy cases, totalling 1,558. The first 12 nominal cases (six models, trials 0 and 1) are included in that total; generation runs these cases first, while historical-reference agreement is checked separately from saved results. Known-model prior/length variants are aliases, not additional observations.

New runs generate the fixed clean records and independent noise streams using the existing Study 1 recipe. Serialized campaign/model labels stay unchanged. Input/evaluation seeds are 2101/2102; initialization/control measurement noise uses 2200+j/2300+j. Reference comparison reuses the resulting saved arrays without simulation. The first 50/100/200 fitting transitions retain their original endpoint indexing; control noise always starts at its first sample.

Each adaptive case fits afresh from its selected prefix and normalized prior; there is no fit cache. Both fitted coefficients and covariance pass into control. Scaling stays on the original calibration grid. R changes only in the QP. `study1_fit`'s optional positive fourth argument scales the normalized prior; omitted/1 gives the nominal computation. `study1_summarize('p06_helpers')` provides the same per-run scoring helpers used by the study summarizer.

Whole-run metrics use [0,120); applied increments use k=1:1199 and exclude the unused terminal input. A held-out prediction score requires all 600 queries. Partial-run rows retain their status; complete-run scores are NaN for incomplete control. Raw Gram `cond(G)` remains distinct from corrected numerical rank. No recovery metric or extra forecast campaign is added.

Paired bootstrap uses mt19937ar/7401 and 2,000 resamples, separate from experimental streams. Configuration/model/trial order is fixed. Initial, pre-contrast and final states are saved. Intervals are contrast-specific. See `p06_schema.m` for the exact table definitions.

## Saved comparison and interpretation

General comparison requires the separately identified canonical sensitivity dataset and canonical Study 1 input/record parents. It computes the original 12-case/204-check baseline table from saved generated cases, in a separate comparison directory. Missing cases or a failed baseline block agreement; no zero discrepancy or PASS table is fabricated during generation.

The baseline comparison requires exact statuses, counts, update/control acceptance and nonfinite masks. Fit states and initialization prediction use the fixed additive `1e-10 + 1e-10*abs(reference)` rule; trajectories use `1e-7 + 1e-7*abs(reference)`; whole-run scores use `1e-8 + 1e-7*abs(reference)`. Timing and machine-dependent condition diagnostics retain their distinct declared roles. These comparison rules do not alter solver or internal-validity limits.

General comparison checks the source mapping and the identities of all supplied records before applying numerical rules. See the [verification guide](../../CROSS_PLATFORM_VERIFICATION.md) for reference inputs and result interpretation. Historical records and the pre-interface regression fixture retain their original identities.
