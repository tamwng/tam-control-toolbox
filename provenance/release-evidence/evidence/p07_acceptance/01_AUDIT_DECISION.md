# P07 consolidated audit decision

## Decision

**Approve the consolidated numerical requirements for implementation and gated execution.** No further policy-only proposal round is required. This decision does **not** assert that the new verifier exists, the quick gate has passed, Windows has reproduced the results, or P07 is closed.

Sending `00_MAC_PROMPT.md` with this package authorizes the bounded implementation, local verification-only commit, and conditional Mac quick/full execution described below. Scientific implementation and historical references remain protected.

Reviewed input: `P07_CONSOLIDATED_ACCEPTANCE_POLICY_REVIEW.zip`  
SHA-256: `fd6ee17e20e096c37cd6337619abbeb931b2ff7a1640a4c622bc91e63c9ebad1`  
Base candidate reported by the package: `75251c47d8c6ffd1806b84d7781ba35a0c2cba61`.

**Notation warning:** P1–P13 below are acceptance-policy family identifiers. They are not the manuscript task identifiers P01–P09. In particular, policy P7 is the raw-Gram diagnostic rule; manuscript P07 is the overall reproducibility/release task.

## Independent checks performed here

- Recomputed all 53 package-manifest file hashes and sizes: all agree.
- Checked the 4,195-row coverage against the original inventory: scope metadata retained, unique coverage IDs, and all rows assigned. Some paths intentionally have separate row predicates or structural variants; dispatch must use those predicates, not a filename alone.
- Compared the supplied protected-file indexes: the same 3,022 paths, bytes and hashes, totaling 1,357,579,926 bytes. This verifies agreement of the supplied indexes, not an independent read of the live Mac archive.
- Recomputed all 48 boundary predicates from the full-precision arithmetic MAT file in Python: results agree with the expected outcomes. The package reports 17/17 saved-array checks, 12/12 guards, and 7/7 copy/prerequisite checks. Those MATLAB checks were not rerun here and cover A1–A5, not the future P1–P13 implementation.
- Applied the proposed matrix screens independently to the two supplied 3-by-3 Gram matrices. Both pass the formation, SVD, and symmetric-eigensystem screens on this Linux/NumPy calculation. Both have robust threshold rank 1 at tau=1e-10, with no rank-boundary overlap; neither raw condition number is screen-resolved. This is a small saved-fixture calculation, not a MATLAB or campaign pass.
- No numerical trajectories, estimators, optimizers, or production MATLAB routines were run in this audit. The live repository and full protected archive were not available here. Windows MATLAB measurements remain absent.

## Consolidated decisions

| Policy family | Decision and retained boundary |
|---|---|
| E0 | Retain exact configurations, source selections, fixed records, declared constants, schema, applicable masks, and meaningful discrete outcomes; retain the original narrow exclusions and P06 gate. Own-run copy equality and cross-run numerical agreement are different checks. |
| A1–A5 | Retain all five previously approved requirements and their narrow precedence. This audit does not widen them. |
| P1 | Approve the stated unit-aware elementwise agreement for the other state/input/forecast arrays. |
| P2 | Approve per-component parameter, derivative, and frozen-coefficient rules. Do not mix physical units in one norm. |
| P3 | Approve calibration, residual, and forgetting rules. Preserve fixed lambda constants, branch outcomes, and A1's identical-calibration prerequisite. |
| P4–P5 | Approve the covariance and Gram entry/spectral rules and the stated formation/decomposition screens. Do not clip eigenvalues, replace raw matrices, or confuse these matrix families. |
| P6 | Approve covariance/Hessian condition comparisons only where the stated resolution and validity screens pass. No Gram exception applies to these quantities. |
| P7 | Approve **only the 19 explicitly listed schema scopes**, plus the separately named supplemental threshold-rank calculation for Study 1/P06. Unresolved raw Gram conditions may receive a qualified verdict only after all specified matrix, source, rank, and outcome checks pass. This is not a claim that those raw numbers reproduced. |
| P8 | Approve residual and identity repeatability targets while preserving all original independent validity thresholds. |
| P9 | Approve the stated physical-coordinate repeatability targets. Do not interpret refinement differences as certified trajectory-error bounds. |
| P10 | Approve scalar summary targets independently of parent-array targets. Preserve original definitions, masks, counts, and selections. Keep the legacy scaled coefficient score a coordinate-based diagnostic; do not relabel it as a physical covariance or universal percentage error. |
| P11 | Approve paired-statistic targets, pairing/seed checks, sign checks and zero-containment checks for the quantities actually reported. No new statistical inference is implied. |
| P12 | Approve the explicitly labeled legacy bookkeeping comparison; all unit-aware component checks remain required. |
| P13 | Approve typed CSV parsing, verified encoding budgets, and the explicitly labeled serialized-only comparison where the unrounded historical aggregate is absent. Validate the 84 family bindings before relying on them; do not invent historical full-precision values. |

The numerical constants are approved **engineering reproduction requirements**. They are neither historical preregistration nor universal solver-error bounds. They were proposed after a strict Mac failure and must be described that way. Freeze them now; do not adjust them in response to later machine results.

## Binding implementation clarifications

1. **Do not confuse equality of a copy with equality across machines.** A fresh Study 6 array must equal its own selected fresh parent exactly. A cross-machine comparison of that computed parent uses its approved numerical rule. Fixed input/noise/query records retain exact checks. At the binding stage, confirm the producing paths of `online/*.mat` query states/inputs and other copied records; a name containing `record` is not sufficient. Source-proven computed copies may dispatch through the already approved physical-quantity family without another tolerance proposal; record the precise mapping. An ambiguous producer still blocks.
2. **P06 baseline-gate residuals are not zero-valued reference targets.** Preserve the original P06 thresholds, row identities, passed flags, and reference hashes. Recompute/check each maximum discrepancy against its actual compared arrays, and retain it. Do not impose exact equality to the historical `maxAbsoluteDifference=0` in addition to the unchanged numerical gate. This is a verification-reporting clarification, not permission to edit `p06_gate.m` or weaken its limits.
3. **Qualification is visible and narrow.** The P7 list is 19 schema scopes, not 19 numerical observations. Count every qualified instance. Passive reductions containing unresolved raw values are themselves marked unresolved; retain their raw values and source paths. Required covariance/Hessian, matrices, trajectories, validity, event/rank counts and publication checks cannot be waived. Zero, required-nonfinite, or ambiguous-boundary cases keep the specified blocking behavior.
4. **Separate numerical agreement from publication conclusions.** The acceptance band is not an uncertainty bound on the exact mathematical solution or a confidence interval. Treat the publication-margin guard as a conservative reproducibility flag. Run it only for the existing explicit manuscript/result-map claims; do not manufacture strict rankings for unreported nearly tied metrics. Exact signs and zero-containment classifications of reported contrasts remain required. A missing manuscript claim map must be disclosed and completed before final P07/publication closure; it does not justify pretending a numerical mismatch passed.
5. **Exact integrity does not require matching generated binary file bytes across machines.** Protected historical files retain exact byte hashes. Candidate/reference scientific MAT data are compared by the frozen scientific schema and rules, not file-header bytes. Fresh local source-path bindings must be exact to that machine's parents; cross-machine absolute directory names/manifest hashes are not expected to coincide. Code SHA and policy hash must coincide.
6. **Store checking information economically.** Check every required entry, but stream per run instead of materializing every Hessian/decomposition at once. Retain per-field counts, maxima, normalized discrepancy ratios, locations, exact source hashes and reconstruction recipes; save detailed matrices/spectra for failures and qualified cases, grouped in compressed per-run evidence. No sampling of required checks. Do not put full trajectories in the review ZIP or commit generated campaign data.
7. **Incidental metadata is not scientific contamination.** The only currently disclosed untracked file is `results/.DS_Store`. Preserve it unchanged and explicitly whitelist that exact untracked metadata path for this verification; do not add it to Git, delete it, or use broad hidden-change flags. Record literal `git status` and label the scientific checkout clean with a disclosed metadata exception, not universally clean. Any other unexpected source change/untracked scientific file blocks. This narrowly supersedes the draft's automatic .DS_Store blockade.

These clarifications are part of this approval, not a request for another policy-design package. All other requirements in the reviewed consolidated documents are retained.

## Execution and release boundaries

Implement only the reviewed verification interfaces and targeted tests. Run full comparator tests, including P1–P13, CSV bindings and verdict propagation. The quick workflow's 49 pre-existing tests are not a substitute for this. Check the actual diff and all protected hashes. Then create one local candidate commit with the immutable policy; do not push/tag/submit automatically.

On each computer independently: verifier tests -> quick gate -> full suite, with the same candidate and policy. A successful Mac local gate may advance to the Mac full suite without waiting for another design review or for Windows to finish. A formally approved P7-qualified result is eligible to advance only with zero unapproved unresolved fields and zero failed mandatory checks. All results must retain the qualification visibly. A real failure stops that machine; do not retry with looser thresholds.

Windows matrix evidence is still required to complete that specific investigation and Windows validation, but is not a prerequisite to implementing or running the approved Mac protocol. Run the supplied small probe on a Windows machine alongside its later verification. Do not claim historical backend identification solely because a current Windows measurement matches.

This phase establishes a **verification candidate**, not the final pedagogical public release. Repository cleanup comes afterward with scientific behavior preserved. A changed final scientific/test commit needs appropriate release verification on that final commit; do not attach an old test report to a different SHA. P08 independent confirmation remains separate from fixed-record cross-machine reproduction.

## External primary checks used in the audit

- MathWorks `cond`: the 2-norm condition is the largest/smallest singular-value ratio; this supports separating unresolved ratios from matrix agreement. https://www.mathworks.com/help/matlab/ref/cond.html
- MathWorks `writetable` and `format`: long-g text serialization and significant-digit format. This supports the serialization distinction, not the selected scientific tolerances. https://www.mathworks.com/help/matlab/ref/writetable.html ; https://www.mathworks.com/help/matlab/ref/format.html
- MathWorks tolerances: stopping criteria have their own roles and are not automatically decision-variable error guarantees. https://www.mathworks.com/help/optim/ug/tolerances-and-stopping-criteria.html

The exact constants and approval are author-level design choices, not endorsements by these sources. Documentation was checked online; execution remains the responsibility of the actual frozen MATLAB environments.
