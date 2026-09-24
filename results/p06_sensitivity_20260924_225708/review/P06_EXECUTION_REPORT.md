# P06 gated execution: compact results review

All 1,558 predeclared cases completed in one invocation. The 12 nominal gate cases passed all 204 comparisons before the remaining 1,546 cases started. Every gate maximum absolute difference was exactly zero in the saved comparison table. No source, numerical setting, record, seed, tolerance, or baseline archive was changed during execution. P06 remains pending audit and manuscript incorporation; P07 and P08 remain unresolved separately.

## Execution and provenance

- Source: `tam-control-toolbox`, `v2-development`, implementation commit `d1f1adb0d7891aba2a9555b7b7c73feb2897e7c7`. The working tree was clean before launch. All 45 reviewed source/hash entries matched before launch and after completion; the runner's source snapshot also matches. This identifies the current P06 source, not the historical producer of Study 1.
- Invocation: `addpath('studies/p06'); run_p06(output,'execute','P06_PRODUCTION_AUTHORIZED');`, with the fresh output `results/p06_sensitivity_20260924_225708`.
- Runner start: 2026-09-24 13:58:06.770 UTC (22:58:06.770 JST). End: 2026-09-24 15:02:32.719 UTC (2026-09-25 00:02:32.719 JST). Measured runner wall time: **3,865.9445834 s = 64 min 25.945 s**. This includes the runner's fitting, control, evaluation, saving, and summaries; MATLAB startup, preflight, exports, packaging, and commit are outside this clock. No new parallelization or fit cache was introduced.
- MATLAB 26.1.0.3346908 (R2026a) Update 5; Optimization Toolbox 26.1; Windows 11 Home, build 26200, 64-bit; Intel Core i7-12700K. Actual active paths and effective solver options are retained. The solver uses the reviewed interior-point-convex options, 1e-8 constraint/optimality tolerances, and 1e-7 normalized KKT rejection threshold.
- Immutable record SHA256: `31b1914e7fe30ea87e0183c586747ea1733a408829145158c41bc55c633635f9`. Saved settings SHA256: `f892c67c6a19d01dba3dfefd457c46d2844e3f9d9ad977bf14888ac8f9a392fe`. Both still match.
- Saved record input/evaluation seeds: 2101/2102. For noisy trial j=1,...,40, initialization/control measurement seeds are 2200+j/2300+j, with sigma=0.01. Trial 0 is noise-free; no process noise was added. The stored arrays were reused, not regenerated. Analysis uses mt19937ar, seed 7401, and 2,000 paired-bootstrap resamples; all saved RNG states are included.
- Historical producing commit, dirty state, OS version, and effective solver options remain **UNKNOWN**. The historical saved environment is quoted separately in provenance. Passing the gate does not establish that historical provenance, and record reuse does not constitute independent confirmation.

## Design, counts, and reliability

The seven one-factor configurations are baseline (R=0.05, prior scale 1, 200 transitions), R=0.025, R=0.10, prior scale 0.1, prior scale 10, 50 transitions, and 100 transitions. The five adaptive models occur in all seven configurations. The known-model reference occurs only at the three distinct R values; its prior/length cases are aliases, not extra observations. Short fitting uses the saved prefix and transfers both fitted coefficients and covariance. All other reviewed settings remain fixed.

There are 38 distinct configuration/model combinations, each with one deterministic case and 40 paired noisy cases: **38 deterministic + 1,520 noisy = 1,558 attempted and completed**. All control records contain 1,200 transitions. There are no terminations, exceptions, invalid held-out scores, rejected initialization updates, rejected online identification updates, control fallbacks, or mapping activations. Every case has 600 finite held-out prediction queries. Saved diagnostic maxima show zero output/input/increment violation. Maximum stationarity residual is 7.680975525819806e-10 and maximum complementarity residual is 9.99720850115937e-9; all residual summaries are finite. All attempted cases and all outcomes are retained.

## Observations for scientific review

These are local Study 1 sensitivity results on the reused paired records. The complete deterministic table, 152 noisy-summary rows, and 116 paired contrasts are included; the following observations do not replace those tables.

- Changing R leaves every fitted held-out prediction score unchanged. Lower R increases input activity, while higher R decreases it. For the Shared model, the noisy median mean absolute increment is 0.0169643 at R=0.025, 0.0148597 nominally, and 0.0125602 at R=0.10. Its corresponding tracking medians are 0.0490638, 0.0490648, and 0.0491005. The Affine and Incorrectly shared models show larger tracking sensitivity to R; no prediction improvement follows from changing a control weight alone.
- Both shorter initialization lengths worsen the noisy median held-out prediction score for every adaptive model. The tracking response is mixed. For Complete quadratic, 50 transitions increases the prediction median from 0.000950494 to 0.00254843 while the tracking median decreases from 0.0490285 to 0.0489376. Affine tracking worsens with shortened fitting. These observations do not establish that poorer prediction causes better tracking: online adaptation and subsequent controller-specific data remain part of the experiment.
- Prior-covariance effects also depend on model and metric. Complete quadratic with prior scale 0.1 has a higher prediction median (0.00137671 versus 0.000950494) and a lower tracking median (0.0489711 versus 0.0490285). Shared and Relaxed have higher prediction medians under the same prior reduction. A tenfold prior does not uniformly improve both prediction and tracking. Some contrast-specific intervals include zero; the full paired table preserves this.
- Across these levels, Shared, Relaxed, and Complete quadratic retain substantially smaller prediction and tracking medians than Affine or Incorrectly shared, but their prediction and tracking rankings differ. The known-model reference is not uniformly the smallest tracking score. This supports bounded sensitivity comparisons, not global robustness, a preferred tuning, or a guarantee linking one-step prediction and tracking rankings.

The example values above are marginal noisy medians. The paired table instead reports the median of trialwise **left-minus-right** differences; these quantities are not generally equal. Its 95% bootstrap intervals are contrast-specific, not simultaneous. Complete-pair counts remain 40 for every reported contrast.

## Definitions and export checks

`predictionRMS` is the stored nonlinear one-step RMSE on 600 common clean held-out transitions after the selected 50/100/200-transition fit. It is not an online prediction or tracking score. Whole-run tracking/input RMS uses k=0,...,1199, corresponding to [0,120); input increments use k=1,...,1199 and exclude the unused terminal committed input. The stored stationary rows use [10,20), [30,40), ..., [110,120), including reference-preview effects. All Plant A state/input quantities use the existing dimensionless units. All definitions remain those of the reviewed Study 1 helpers.

The compact scalar export loads only `item`, `scores`, and `failure` from each saved MAT file. It never loads the `result` trajectory variable, refits, propagates a model, calls scoring helpers, or generates new trajectories. The scalar MAT preserves binary values; CSV numbers use 17 significant digits and retain NaN/Inf explicitly. JSON metadata converts nonfinite numbers to null, so consult MAT/CSV where non-applicability matters.

`P06_RUN_MANIFEST.csv` is the unchanged approved execution plan and retains its original `PROPOSED_NOT_RUN` field. Actual attempts and statuses are in `tables/runs.csv` and `scalar_data/P06_CASE_SCALARS.csv`; every planned ID is matched to a completed actual record. The manifest alone is not execution evidence.

Checks actually performed after execution:

- Unique 1,558-case manifest and actual-record agreement; correct 38/1,520 split; 40 noisy cases per applicable configuration/model; known-model non-applicability and aliases.
- 12 gate identities, 204 passed checks, and hashes of the historical gate records.
- 608 aggregate median/quartile/IQR comparisons and all 116 paired medians/counts against saved scalar cases. Bootstrap intervals and RNG states were preserved, not resampled for this export audit.
- 12,464 exact item-versus-saved-score comparisons and 65,436 scalar-field comparisons against the runner table. CSV-only comparison tolerance is 2e-14 absolute plus 2e-12 relative; it does not change any baseline-gate tolerance.
- Full 1,558-file raw index with status, completion, transition count, bytes, and SHA256; postflight source/snapshot and immutable record/settings checks.

The retained Gram diagnostic is legacy Study 1 `cond(G)`, **not** the thresholded numerical-rank diagnostic in Appendix A. No new rank analysis, covariance adjustment, or P05 resolution is claimed. The approved implementation review recorded 17 passing local tests; those tests and the global suite were not rerun during this execution, as instructed. A sandbox-only MATLAB startup attempt for scalar export failed before executing the export; the read-only export then completed outside the sandbox. The production invocation was not restarted.

## Compact package and retained archive

The user's later compact-package instruction supersedes the handoff's proposed 76 trajectory attachments. The ZIP contains no per-run trajectories. It contains the gate report; all runner tables; exact per-case scalar, window, initialization, diagnostic and exception records; configurations, manifest, seeds, provenance, analysis RNG states, source snapshot, and raw-file index. These suffice to reproduce all supplied aggregate summaries without transporting trajectories. Recomputing an individual trajectory-derived score from samples would require its indexed local raw file.

All **1,558 raw files, 979,851,663 bytes (979.85 MB; 934.46 MiB)**, remain unchanged under `results/p06_sensitivity_20260924_225708/runs`. No raw archive was deleted, compacted in place, or bundled for transfer. The external ZIP receipt records the final compressed size and integrity check. The user's explicit commit instruction supersedes the handoff's no-commit clause; the bounded result directory is committed locally, with its commit receipt included in the ZIP. Nothing is pushed, merged, tagged, published, or incorporated into LaTeX.

No scientific next action has been executed. The audit department should review the retained results before deciding how to address P06 in the manuscript. P07 historical provenance and P08 independent confirmation remain separate open items.
