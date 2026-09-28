# P07 consolidated preflight: one decision on B1 and B2

## Decision and authority

**Approve the two bounded verification fixes below, subject to their regression and saved-data checks.** This is a decision about the required repairs, not a declaration that the repairs are implemented or that P07 has passed.

- **B1:** a scope-specific amendment to E0 for the *outer MAT-variable namespace* of Study 6 `settings.mat`, F2710. Match retained variables by exact name rather than by their loaded order. All nested requirements remain unchanged.
- **B2:** bind the Study 2 plot/report check of raw `maxStoredCondition` to the already approved P6/P7 numerical/qualified rules, with exact own-source reduction and all original rank/count/validity checks retained. This is a new reporting-site binding, not automatic coverage under F0698.

**No new numerical limit, rank threshold, scientific calculation, input record, reference result, or published claim is approved for change.** Preserve strict defaults and old failures. Record the two amendments explicitly; unchanged numerical constants do not mean an unchanged effective policy.

The user has paused execution. This review does not start work in another department. The accompanying prompt is for a separately launched repair task and authorizes only implementation, verifier regressions, and saved-data/plot revalidation. **No candidate commit, certification quick/full run, Windows run, push, tag, cleanup, or LaTeX edit is authorized.** After local checks pass, return readiness and wait for explicit instruction.

## 1. Basis, actual progress, and limits

Read first: the supplied `FINAL_REVIEW.md` and `BLOCKERS.md` (unchanged copies included under `source_evidence/`). Additional basis: `GROUPED_BLOCKERS.json`, `STAGE_COVERAGE.csv`, `EFFECTIVE_DIAGNOSTIC_POLICY.json`, the six source-context files, the two blocker fixtures, and their exact-value exports.

Input archive: `P07_CONSOLIDATED_PREFLIGHT_REVIEW.zip`.

SHA-256: `f748af8a9b9a43e4b7f7f5a8e43680b543a6907845a9fe47feca95cd198a7931`.

### Independently checked here

- All **160 manifest-listed members** match their listed sizes and SHA-256 values. The manifest itself is the sole unlisted archive member.
- All six supplied source-context copies match their source-context hashes.
- The file-coverage table contains 2,877 entries: 2,876 `PASSED`, one `FAILED`; the failed entry is Study 6 `settings.mat`.
- An independent SciPy/NumPy traversal of the complete settings fixture finds no retained nested order, represented class/shape, or value differences after applying **only the existing metadata exclusions** and ignoring order **only at the outer namespace**. This is not execution of MATLAB's blocked descendant checks or independent validation of every external source link.
- All 15 adaptive Study 2 rows were checked from their saved condition histories: the selected indices agree, each side selects 750 count-50 windows, maxima and first-max indices match the supplied exact-value ledger, and the historical maxima match the reference CSV binary64 values.
- All 15 raw maxima fail the legacy 32-eps cross-platform assertion. **Twelve** pairs satisfy the existing P6 scalar inequality alone; the three P3 pairs do not. Scalar arithmetic alone never establishes full P6 acceptance: resolution and parent checks are still required.
- The 17 same-index witness pairs (the union of both maxima's indices for each case) have maximum matrix-entry discrepancy `7.771561172376096e-16` and satisfy the P5 entry inequality in this independent calculation. Nominal ranks computed here using the existing relative threshold `1e-10` agree within each same-index pair. This does not check every original regressor, formation/decomposition screen, or full-window rank count; those remain required locally.

See `03_INDEPENDENT_CHECKS.json` and the included Python audit script. These are review calculations, not replacement MATLAB acceptance code.

### Reported by MATLAB, not independently executed here

The package reports 279/279 final implementation tests, all 2,073 control cases completed, Studies 1–5 and P06 file comparisons passed, 340/341 Study 6 files passed, 329 valid Study 6 batches and 27,296 finite paths, and all 13 paper-export families passed. It reports 641,700 Gram qualification instances and preserves their unresolved numerical status. Historical self-consistency passes are separate, not cross-platform execution evidence.

The package reports 3,022 protected files / 1,357,579,926 bytes unchanged, 119 scientific-source files unchanged at this checkpoint, and 6,196 development dependencies checked. The raw approximately 8.95 GB local archive and live repository were not available here. The large ledger totals were supplied as compact summaries, not independently recomputed from all local raw ledgers.

No MATLAB execution occurred in this audit. An accepted scientific-stage diagnostic does not erase B1's unexecuted descendants or B2's unexecuted later assertions/exports. There is no completed final cross-machine certification.

## 2. B1 — Study 6 MAT-settings schema order

### Source facts

- Coverage: **F2710**, `study6/settings.mat`, root quantity `value`.
- After the existing `environment` exclusion, current names are `[sources,cfg]`; reference names are `[cfg,sources]`.
- `source_context/studies/p07/ejc_compare_results.m:259–274` currently rejects ordered field-name inequality before recursion; line 268 is the blocking assertion.
- Both `run_study6.m:29–37` and `ejc_preflight_study6.m:18–23` load the five source settings and save with the explicit argument list `cfg,sources,environment`. The observed loaded-order difference does not establish a particular OS/backend cause.
- The current cfg includes `sourceMode` and `sourceDirectories`; `exclusion_reason` at comparator lines 367–377 already treats these, `cfg.sources`, and `cfg.execution` as source/execution metadata. No new metadata exclusion is requested.

### Binding fix

Only when all identifying predicates match **portable mode + Study 6 + exact `settings.mat` + F2710 + outer `value` container**:

1. Keep the exact scalar-struct class/shape requirement.
2. Apply the existing exclusions unchanged and log their actual values/source bindings.
3. Require the exact retained variable-name set `{cfg,sources}`. A missing, additional, or renamed retained variable fails. Do not accept merely overlapping names.
4. Dispatch children by their exact names, using a deterministic traversal order only for comparison. Retain the raw current/reference orders in evidence. Do not rewrite either MAT file or reorder either stored object.
5. Recurse through **every retained descendant**, preserving the existing nested field order, classes, shapes, cell/source order, scientific values, configured thresholds, selection arrays, and source relationships. Do not recursively sort structures or weaken E0 elsewhere.
6. The root namespace result cannot declare the whole file passed. A missing or failed descendant/source requirement keeps the file blocked.

This is a **narrow policy applicability amendment**, because the old effective E0 explicitly required order. Do not present the original failure as if it passed or call it an established MATLAB defect. Preserve the original strict comparator behavior when portable mode is absent.

### Minimal files

Edit the outer-container dispatch in `studies/p07/ejc_compare_results.m`, with a narrowly named P07 helper if useful; update the effective policy's scoped amendment/coverage explanation and add tests. No edit to `run_study6.m`, `study6_settings`, the scientific evaluators, or the settings MAT files is needed.

B1 regression requirements are in document 02. Revalidate the actual settings file against the immutable reference and rerun its relevant local source/descendant checks. Existing diagnostic calculations need not be regenerated.

## 3. B2 — Study 2 Gram assertion in the plotting/reporting path

### Source facts and important distinctions

`study2_gram_report.m:44–51` computes `maxStoredCondition` as the maximum of the **stored raw** `gramCondition` history over recorded steps `1:nSteps` with `gramCount==50`. It is not the subsequently calculated numerical-rank convention's `conditionMax`.

`study2_gram_report.m:112–140` first checks coefficients, window/rank counts, threshold, model identity, and zero invalid windows; lines 133–140 then demand equality or a difference at most `32*eps(max(1,abs(reference)))` against the historical CSV. `plot_study2_journal.m:25–26` invokes this report before producing the figure. Its later lines 55–57 require plotted points to equal their own source table exactly. The report removes `maxStoredCondition` at line 95; returned `conditionMin`/`conditionMax` retain the original rank-based convention.

The original plot invocation stopped at **A, amplitude 0.2**. The separate reduction audit found the same scalar predicate fails for all 15 adaptive rows; it did not execute the original plotter's remaining checks.

For the first row, the current maximum is `446704.7162545172`, reference `446704.7162547792`, discrepancy `2.619926817715168e-7`, old bound `1.862645149230957e-9`. It satisfies the existing P6 scalar inequality by a large margin.

Do not describe all failures this way. P3 at amplitude 0.2 has current maximum `3.4063884353363509e22` and reference `2.7931691237344476e22`. All three P3 maxima fail ordinary P6 numerical agreement. Their route, if every required guard passes, is the existing **qualified passive-Gram treatment**, not a claim that their raw maxima agree.

### Binding fix: same-run linkage first; cross-run interpretation second

Authorize an optional **verification callback/context only at this named raw-maximum assertion**, preserving the strict default and the original formulas.

For every eligible adaptive model/amplitude row, not merely currently failing rows:

1. Establish exact row/source identity and unchanged file hashes, units, model, scenario, amplitude, parameter count, time/window definitions, and selection `gramCount==50` through `nSteps`. Use the actual pinned historical MAT and CSV, not a regenerated or altered reference.
2. On **each side separately**, recompute the maximum from that side's complete selected stored history. Its recorded scalar/selector must be its own reduction. Check the historical CSV against its historical MAT reduction using its unchanged own-source/representation contract; the broader cross-run P6 bound cannot forgive a broken own-source link.
3. Bind to the validated **F0533 `result.gramCondition` history and its original parent data**, with the exact full-window selector. F0713 is a related run summary, not an assumed exact alias of this selection. Do not accept a previous overall “Study 2 passed” flag as sufficient parent evidence.
4. Execute the existing per-index P5/P6/P7 checks over the complete selected history, preserving regressor/matrix/spectral/source requirements, original ranks/counts/validity, and outcomes. Reuse hash-bound valid ledger records where the existing protocol permits it; do not silently skip a necessary parent check.
5. For screen-resolved comparisons, retain P6 unchanged: `abs(a-b) <= 1e-8 + 1e-7*abs(b)`, plus all its resolution/validity requirements. If the required parent condition is unresolved, allow only the previously approved P7 passive-diagnostic qualification with its full guards. The maximum inherits an explicitly qualified status when its numerical agreement is unresolved; never turn a very large discrepancy into a P6 pass.
6. Preserve each side's own extremum witness. At different maximizing indices, check the two histories/matrix parents at **corresponding indices**, including the union of both witness indices as required. Do not compare a current matrix at index 338 to a reference matrix at index 182 as if they were the same observation. Do not demand identical deficient ranks at different times. This plotting assertion previously had no cross-run argmax requirement; do not add one or extend the separate F0698 QP-locator amendment.
7. Retain every original rank/report assertion, `relativeThreshold=1e-10`, valid/invalid window count, known-model N/A convention, output selection, figure value, and source relationship. Do not change the definition or output of `study2_gram_diagnostic`, rank-based `conditionMin`/`conditionMax`, or the figure's performance values.
8. Preserve raw finite/nonfinite values and the original strict failures. Matching infinity, small differences, a large condition value, or matching nominal rank alone never grants acceptance. Use the existing permitted source-specific nonfinite routes only.

### Minimal implementation boundary

A P07 helper should implement the portable binding. Permit only the minimum plumbing necessary:

- an optional comparison callback/context and, if needed, optional verification-evidence output in `studies/study2/study2_gram_report.m`;
- optional forwarding through `plot_study2_journal.m`;
- the corresponding P07 plotting/preflight caller, scoped policy/coverage binding, and regression tests.

The old one-/two-argument Gram-report calls and up-to-three-argument plotter calls must retain their original strict behavior. No general `skipCheck`/`portable=true` bypass, replacement reference CSV, copied Gram algorithm, change to the shared numerical comparator, or catch-and-skip path is allowed. Invalid/missing callback evidence fails closed. The callback only replaces this assertion in portable mode; all subsequent rows and plotting assertions still execute.

Portable logging must distinguish numerical agreement from qualified unresolved maxima; do not print that all raw maxima match exactly if some are qualified. Put qualification details in the P07 evidence/sidecar, without altering the published figure data or the established rank-report table schema.

**Source-manifest nuance:** `study2_gram_report.m` is included in the supplied 119-file scientific-source manifest. Adding the permitted verification hook changes that file's hash even though its scientific calculation is unchanged. Preserve the old manifest and old file; record an exact authorized old/new hash and narrow diff as a reporting-interface exception. Do not delete it from integrity checking or continue claiming all 119 file bytes are unchanged. Every other protected scientific calculation/file and all 3,022 historical protected records retain their existing integrity requirements. The plotter's hash change must likewise be explicit. A separately versioned amendment/integrity annex may authorize only these exact hooks; it is not a blanket mutable-source allowance.

B2 regressions and full saved figure/source revalidation are required by document 02. No trajectory refit, controller run, or bootstrap regeneration is needed to check these two blockers.

## 4. Completion gate, identity, and pause

Current recorded base HEAD: `de77ad73531abe100499abc1dc45099026f75667`.

Current diagnostic policy SHA-256: `f9c1dd9a4282788de1c3f8e7b4d2a7e4dede359aba483f799475b29bae658ad6`.

Current development snapshot SHA-256: `731a06c123e7a6332cb006f8c2c682a9439a944e83ddc5ee8c4a6c107e4897d9`.

These identify the supplied, **not finally certified**, checkpoint. If the repairs are implemented, preserve it and record new development source/policy hashes. Numeric constants and rank definitions must remain exactly fixed. Do not claim the effective policy stayed the same after changing applicability/bindings.

Once all targeted and integrated verifier checks pass, return an updated **diagnostic-readiness package**: B1 full descendant/source verdict; B2 all 15 adaptive comparisons and all 18 model rows' report/figure checks; qualification counts; complete preserved old/new verdicts; coverage update; regression results; source/reference integrity; minimal diff and hashes; unresolved items, if any.

**STOP UNCOMMITTED.** No fresh production quick/full cycle, Windows execution, or final candidate commit is authorized. The user will separately authorize freezing and final Mac/Windows certification. Historical self-checks, development-data revalidation, or figure regeneration cannot be reported as that certification. P07 and P08 remain open; no manuscript or repository pedagogy pass starts here.
