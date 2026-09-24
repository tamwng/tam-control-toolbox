# P06 — Gated campaign execution only

## Authorization

The manuscript audit department has reviewed `EJC_P06_Implementation_Review.zip`. Execute ONLY its fixed seven-configuration Study 1 sensitivity design. This authorization covers the 12-case baseline gate and, ONLY if all gate checks pass, the remaining 1,546 cases. It does not authorize new configurations, tuning, other studies, source changes, or manuscript edits.

Use the implementation already present in the authorized `tam-control-toolbox` repository on `v2-development`. Do not reapply the review patch over current files. The reviewed implementation commit is `d1f1adb0d7891aba2a9555b7b7c73feb2897e7c7`, based on `05000a19bad01e52d852e1d63ac21f607d7596ae`. This is new P06 provenance, NOT a claim about the source that produced the historical studies.

## 1. Before launch

- Check the reviewed source hashes against `P06_FILE_LIST.csv` and the reused-source hashes in `P06_SOURCE_PROVENANCE.json`. Verify the active function paths resolve to these files. If source bytes, configuration, or dependencies differ, STOP AND ASK; do not reset the repository or discard changes.
- Confirm the immutable input/noise record has SHA256 `31b1914e7fe30ea87e0183c586747ea1733a408829145158c41bc55c633635f9` and the saved settings file has SHA256 `f892c67c6a19d01dba3dfefd457c46d2844e3f9d9ad977bf14888ac8f9a392fe`.
- Preserve the reviewed solver options and all seven factor settings. Capture the actual execution environment and source snapshot using the existing runner. Do not substitute a commit label for source integrity.
- Confirm a fresh output directory and sufficient storage. Never overwrite or mix into an existing campaign. Do not perform the codebase pedagogical pass now.
- Use the reported local tests as the reviewed implementation check; do not launch the global test suite or unrelated verification campaigns. If there is a reason to rerun a local test, use only `run_p06_tests` with a fresh test-output directory.

## 2. Launch the existing gated runner

From the repository root in MATLAB:

```matlab
addpath('studies/p06');
tag = char(datetime('now','Format','yyyyMMdd_HHmmssSSS'));
output = fullfile('results',['p06_sensitivity_' tag]);
run_p06(output,'execute','P06_PRODUCTION_AUTHORIZED');
```

The existing runner executes the six baseline models at trial 0 and trial 1 first (12 cases). Their results count once within the 1,558-case total. It must not execute any non-gate case unless every gate case passes.

The proposed gate tolerances in `p06_gate.m` are approved as NEW comparison tolerances, not historical solver tolerances:

- completion, number of transitions, identification/control acceptance: exact;
- fitted theta/beta/covariance histories: absolute 1e-10 plus relative 1e-10;
- held-out initialization prediction RMSE: absolute 1e-10 plus relative 1e-10;
- x/y/u, online theta, and prospective one-step prediction: absolute 1e-7 plus relative 1e-7;
- whole-run tracking/input/activity scores: absolute 1e-8 plus relative 1e-7.

Array shapes and finite/nonfinite masks must agree. Keep the exclusions already declared for timing and condition estimates. If a gate fails, preserve the saved attempts and gate diagnostics and STOP. Do not loosen thresholds, change seeds/options, or alter the baseline to obtain agreement.

If all 12 pass, the runner may proceed directly to the other 1,546 cases without another approval round. Do not rerun the gate in a second output folder merely to start the remainder.

## 3. Fixed execution boundaries

- Seven OFAT configurations only; five adaptive models under all seven configurations, plus the known-model reference at the three distinct input-increment weights.
- Total: 38 deterministic cases and 1,520 paired noisy cases; 1,558 unique attempted cases if execution is uninterrupted.
- Reuse the saved records. Shortened fitting uses prefixes; control noise remains independently indexed. Carry both fitted coefficients and covariance into control.
- No changes to raw model initialization, scaling grids, horizons, reference preview, constraints, scoring windows, solver options, noise levels, or analysis seed 7401 / 2,000 paired-bootstrap resamples.
- No new parallelization, fit cache, checkpoint-resume mechanism, algorithm fork, or optimization of execution time.
- Keep baseline reproduction checks distinct from scientific outcomes: a reversed ranking, larger error, non-recovery, or a documented numerical termination in a changed configuration is a result, not grounds for retuning or selecting replacement trials.
- Retain all attempted cases, rejected updates, fallbacks, terminations, nonfinite entries, and exceptions. Never replace failed-run scores by zero or treat finite prefixes as complete runs. Report the existing eligibility and complete-pair counts.
- The existing runner records case exceptions. Inspect and report them explicitly; programming/setup/serialization failures must not be interpreted as controller performance. If such a problem or an interruption requires a code change or continuation strategy, STOP AND ASK before fixing or restarting anything. Do not silently relaunch an entire campaign.
- Do not relabel the legacy raw Gram diagnostic as the thresholded rank diagnostic in Appendix A. Do not reopen or claim to newly resolve P05 through P06.

## 4. Return an audit-ready result artifact

Create `EJC_P06_Results_Review.zip` after execution (or a clearly marked partial package after a stop). Include:

1. `P06_EXECUTION_REPORT.md`: source identity; actual start/end and measured runtime; gate outcome; planned/attempted/completed/terminated/exception counts; exact deviations, if any; no manuscript prose or unsupported robustness claims.
2. The exact executed `P06_RUN_MANIFEST.csv`, configuration definitions, and known-reference aliases.
3. All runner-produced tables: `baseline_gate.csv`, `runs.csv`, `deterministic.csv`, `noisy_summaries.csv`, `paired_contrasts.csv`, and `known_reference_aliases.csv`. Clearly distinguish proposed manifest rows from actual attempts.
4. `execution_provenance.mat`, `analysis_randomness.mat`, the actual source snapshot, and a readable JSON/CSV export of provenance and gate/count summaries. Keep historical unknowns labelled UNKNOWN.
5. A complete raw-run index with run ID, relative MAT-file path, status, file size, and SHA256 for every generated case. Retain ALL raw run files in the immutable campaign directory.
6. For a compact review upload, include the MAT files for trial 0 and trial 1 of every distinct configuration/model combination (76 files if all finish; these include the 12 gate cases). Selection is fixed by trial ID, not by outcome. Also identify every unsuccessful case and include its diagnostic/error record; if attachments would be too large, provide a separate supplemental ZIP, not an unreported omission. Do not discard other raw results.
7. A neutral summary of how prediction, tracking, input activity and completion change across the predefined levels. Report opposite or mixed findings without tuning them away. Preserve the original sign convention and contrast-specific, not simultaneous, interval interpretation.

Before delivery, check manifest uniqueness, complete attempted denominators, 40 noisy attempts per applicable model/configuration, known-model non-applicability, gate traceability, and consistency of per-run scores with the aggregate tables. If a check cannot be completed, state exactly what is missing. Exporting existing results does not authorize changing their definitions.

## 5. What must remain untouched

Do not edit MATLAB source files, baseline archives, other study folders, manuscript files, response-letter files, or other departments' repositories. Write only into the new P06 result/export area. No commits, pushes, publication, arXiv upload, or submission are authorized by this execution instruction.

Keep P06 unresolved until the audit department has checked the results and prepared manuscript text. P07 historical provenance and P08 independent-confirmation status remain separate. Reuse of historical paired records is intentional and does NOT constitute independent confirmation.

Return the ZIP and a summary of no more than ten lines. Then STOP. The manuscript audit department will interpret the results and provide the exact LaTeX insertion; do not write completed-sounding reviewer responses yourself.
