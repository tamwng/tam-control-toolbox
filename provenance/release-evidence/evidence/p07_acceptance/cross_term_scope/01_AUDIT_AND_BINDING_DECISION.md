# P07 — cross-term claim applicability: audit and bounded amendment

## Decision

Approve a **versioned, post-failure correction to publication-claim applicability**. Do not enlarge any numerical tolerance, alter a scientific result, or call the old full run a pass.

The stopped run remains **FAILED** under candidate `894eba817eaa43b882f849c5f830f64a8d6dbe39` and policy SHA-256 `05c20f48e37a352f62ad3fb8975b7803be10ecd9e528bfeff61ac5005c97c451`. The new acceptance implementation and policy require new identifiers. This amendment was motivated by an observed failure; subsequent documentation must not portray it as a rule fixed before that observation.

**Purpose:** distinguish a continuously valued algebraic error-decomposition diagnostic from a published directional claim. A cross term is signed, but the paper does not assert that every stored cross term has a reproducible strictly positive or negative sign.

## 1. Checked facts

The 26 manifest-listed files have matching byte counts and SHA-256 values. The auditor independently checked all 858 failed-row identities, binary64 encodings, differences and sign changes. Their reference values and row keys also match the full historical CSV retained in the previously supplied numerical archive; its SHA-256 is `03d3f087dfb0d9bb752a13471c078d8f30550a0aad87b47cd54a9391994cc1f7`.

All 858 scalar pairs pass the existing core P10 agreement requirement, even before adding the separately approved CSV representation budget. The largest difference is `5.2758276779739026e-17` squared state units. The largest absolute values among these failures are `4.4402839467416797e-17` current and `3.77163518020052e-17` reference. These are not a proposed new threshold.

The visited file-verdict table contains 526 passes and one failure. The supplied before/after integrity manifests are identical and report 3,022 protected files / 1,357,579,926 bytes. The auditor checked those manifests, not the 1.36 GB of local protected bytes independently. The report states that 258 trajectories completed, 241 prerequisites passed, and 106,008 executed numerical leaf checks had zero bound failures. Eight Study 1 files, later studies, P06, and the paper gate remain unaccepted/unexecuted as specified in the original report. These limitations remain visible.

## 2. Definition and failure mechanism

The defining `studies/study1/study1_measured_audits.m` was recovered from an earlier supplied source snapshot and its SHA-256 matches the exact frozen dependency manifest:

`aaa40dc3279d962ef3c06e6f08d637cb0700cf2acfde3a364c92d3feee8937d8`.

For each query the producer defines:

- `em = zMeasured - zTrue` (measured-initialization nonlinear-model error);
- `ef = zAffine - zMeasured` (freezing error);
- `et = zAffine - zTrue`;
- `cross = 2*em*ef`;
- `meanCrossTerm = mean(audit.crossTerm(:,h,mode))` over the original selected queries.

This is **not a paired tracking-performance difference**. In this measured-initialization diagnostic, `em` includes the effect of the measured starting state; it must not be relabeled as clean-initialization model error.

The producer separately checks the error identity, squared-error identity, initialization identity, first-step contact, and applicable affine/noiseless properties. Those checks remain mandatory with unchanged limits.

The frozen `ejc_portable_leaf` applies `ejc_claim_check(...,"signedContrast")` to every `N_CROSS` table field named `meanCrossTerm` or `meanCombinedCrossTerm`. That claim check requires exact equality of `sign(current)` and `sign(reference)`. It runs even after numerical comparison succeeds, and irrespective of whether a directional claim is made for that row. The generic failure message about conservative margins is misleading for this branch: no margin was used; the failure was exact sign equality.

The current code therefore implemented an overly broad **policy requirement**. This is not permission to silently label an intentional frozen rule as an implementation typo.

In the latest supplied manuscript checkpoint, Section 6.5, Eq. (66), retains the cross term in the squared-error decomposition. The text states that model and freezing errors can partly cancel. The measured-initialization paragraph reports initialization-error magnitudes, not strict signs for all 2,580 exported diagnostic rows. There is no scientific requirement here that a mathematically zero first-step interaction acquire the same sign after finite-precision evaluation. Small values can still be representable and meaningful in other settings; magnitude alone does not establish exact zero or its cause.

## 3. Binding semantic rule

Keep **all quantitative requirements unchanged**: units, absolute/relative bounds, serialization checks, parent-array checks, exact identities/selections/masks/counts as applicable, numerical identity residual checks, solver validity, and scientific outcomes. Keep the Gram qualifications separate and unchanged.

Introduce a narrowly scoped verification-side distinction:

### A. Descriptive algebraic cross-term diagnostic

For an existing, source-verified algebraic cross-term reduction with no explicitly claimed sign/order/interval inference:

- Apply the unchanged P10 or P11 numerical agreement rule, as applicable, and all source/parent/identity requirements.
- Do not add exact raw sign equality or exact interval-zero-containment solely because this descriptive quantity is signed.
- Preserve the raw signed values, signs, endpoints, discrepancies, source keys, and old failures. Do not take absolute values, round/snap to zero, modify CSV/MAT outputs, or discard a row.
- Where the raw sign/interval classification differs but the quantitative requirements pass, record a descriptive status such as `NUMERICAL_AGREEMENT_SIGN_NOT_ASSERTED`, with claim applicability explicitly `NOT_ASSERTED`.
- This status means numerical agreement under the unchanged requirements, **not exact equality, a proven true-zero value, or reproduced statistical significance**.

### B. Explicit published directional claim

A statement that a specified contribution cancels/amplifies error, a specified model has lower error, a paired contrast has a particular sign, or a confidence interval has a claimed relation to zero still requires its existing claim guard and precise source mapping. If the claim changes or cannot be substantiated, it remains blocked even when numerical agreement passes.

Preserve all existing P11 performance-contrast sign/interval guards, non-cross-term metrics, thresholds, outcome classifications, sign conventions, and true discrete invariants. Do not modify the default behavior of the generic `signedContrast` check.

### C. Missing or ambiguous applicability

Do not silently infer `NOT_ASSERTED` from a small magnitude. The relevant manuscript/response passage, row role, and source formula must establish applicability. An ambiguous or missing mapping remains a reported blocker, not a generic pass.

## 4. Authorized scope, not a whitelist of failed rows

`04_SCOPE_CANDIDATES.csv` identifies 27 existing `N_CROSS` cross-term-reduction scopes and 36 P11 field candidates from the supplied prior field inventory. It is a **candidate enumeration**, not 63 unconditional waivers. Confirm it against the active frozen inventory before binding it.

The direct applicability correction covers the exact source-verified `meanCrossTerm` / `meanCombinedCrossTerm` reductions in those scopes. The immediate failure is F0277, Study 1 `tables/measured_initialization_audit.csv`, and the rule applies to **all its existing rows**, not only the 858 observed failures.

For P11, the amendment is restricted to rows whose exact metric metadata identifies the algebraic `meanCrossTerm` or `meanCombinedCrossTerm` and whose defining reduction/source is verified. It does not apply to tracking, prediction RMSE, coefficient, recovery, or other performance contrasts. Preserve the paired samples, seeds, bootstrap membership, reduction methods, all numeric endpoint checks and ordered lower/upper bounds. Only a nonasserted sign/zero-containment inference is inapplicable. A published inference for a cross-term contrast retains its guard.

Complete one compact applicability table before committing: coverage ID, file, exact field/row selector, source formula, units, descriptive/claimed role, relevant manuscript passage, and guard. Do not change classification based on observed current/reference signs. Do not extend by fuzzy field-name matching or by globally turning off publication checks.

## 5. Required tests and implementation boundaries

Verification/policy files and verification-only orchestration are editable within this amendment; scientific producers, settings, seeds, fits, optimizers, reduction algorithms, reference files and outputs are not.

Add tests for:

1. the actual F0277 failure: strict V4 sign failure preserved; new descriptive classification allows quantitative agreement only with valid parents;
2. all 858 fixtures and all 2,580 rows rechecked without selection/exclusion;
3. non-cross-term performance contrast sign reversals still failing;
4. an explicitly asserted cross-term sign/interval change still failing;
5. failed numeric bounds, NaN/Inf, wrong units, missing source, altered query membership, and failed decomposition checks still blocking;
6. P11 cross-term-only row dispatch, with unchanged strict behavior for every other metric;
7. exact lower/upper interval order and original counts preserved;
8. a numeric mismatch cannot be rescued by `NOT_ASSERTED`;
9. new verdicts do not silently count as exact equality or bypass the full stage/paper gates.

Use the existing numerical primitive. No new epsilon cutoff, empirically enlarged zero band, or extra allowed precision loss is authorized. Do not create another broad acceptance-policy design round.

## 6. Reuse the computation without rewriting its history

There is no scientific need to regenerate Study 1 solely because a post-processing acceptance rule changes, provided its scientific source and data dependencies are demonstrated unchanged. The preferred next check is **read-only revalidation of all 535 completed Study 1 output files**, including the eight previously unprocessed ones, against the immutable Windows reference. Preserve the failed comparison directory; write a new comparison directory.

After implementation tests and saved-output checks pass, freeze a new candidate and policy hash, run a fresh quick gate, and repeat the full Study 1 revalidation using the committed verifier. No scientific stage may start while any mandatory predecessor gate fails.

If the existing infrastructure supports safe stage reuse, continue the remaining scientific stages using those verified outputs. Record producing commit C0 for reused Study 1 data and verification commit C1 for their new assessment; subsequent stages record their actual producing commit. Do not relabel reused data as freshly generated at C1, and do not copy an old success flag instead of rerunning its checks.

A minimal P07-only reuse/resume entry point is authorized if it preserves the original fresh-run default and reuses the exact existing stage and comparison functions. It must have tests rejecting changed scientific dependencies, changed data hashes, failed or incomplete predecessor stages, wrong policies, and historical fallback for fresh-source diagnostics. If this cannot be implemented safely within verification-only orchestration, use a fresh full run after the new quick gate rather than inventing provenance. A fresh rerun is then a workflow limitation, not a scientific remedy.

This is revised-policy reproduction, not independent confirmation. Windows #2 must ultimately be assessed under the same final policy. Do not update a checkout while MATLAB is using it; preserve any old-policy Windows run and its producing provenance.

## 7. Release and reporting boundaries

P07 is not closed. The explicit whole-paper claim map remains a final closure item; this narrow cross-term map does not establish every publication claim. P08 is unchanged. Do not edit LaTeX or claim a clean, prospectively frozen full-suite pass. Any eventual paper sentence must describe the actual producing/revalidation commits and machines accurately.

## General numerical context, not the source of acceptance limits

MathWorks documents finite-precision roundoff/cancellation and magnitude-based numerical comparisons. These sources support the general distinction between computed values and exact arithmetic; they do not prove the exact source of this Mac/reference difference or endorse the project-specific constants.

- Floating-Point Numbers: https://www.mathworks.com/help/matlab/matlab_prog/floating-point-numbers.html (round-off and cancellation sections; accessed 2026-09-27).
- AbsoluteTolerance: https://www.mathworks.com/help/matlab/ref/matlab.unittest.constraints.absolutetolerance-class.html (accessed 2026-09-27).

No MATLAB was executed in this audit. Detailed independent compact-package checks are in `02_INDEPENDENT_CHECKS.json`.
