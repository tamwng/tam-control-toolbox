# HQ audit — Study 2 maximum-location failure

## Decision

Approve a versioned, post-failure amendment to the **cross-run maximum-locator
requirement** for F0698, Study 2 `tables/run_diagnostics.csv`, `qpConditionMax`,
and source-verified exact aliases of that same quantity. Apply the rule to all
eligible rows, not a whitelist of the two failures. Eligibility, unchanged limits,
and required checks are specified in document 02.

This amendment does not change the maximum calculation, QP, covariance/Hessian
accuracy requirements, scientific code, statistical interpretation, or reference
data. It does not qualify an unresolved QP Hessian using the Gram exception.

Also change the NEXT workflow to a **consolidated diagnostic preflight**, described
in document 03. Do not immediately restart the full certification run. This
supersedes the preceding automatic `new commit -> quick -> full` instruction for
this work session only. Final fresh verification remains required afterward.

## 1. Source and identity

Reviewed input: `P07_MAC_de77ad7_COMPACT.zip`.

- Input ZIP SHA-256:
  `5058d6abbf2ec38ddc684e44ee55ee6f788ef75ff8b387a8a54a62d243dfb9fe`.
- Failed candidate: `de77ad73531abe100499abc1dc45099026f75667`.
- Frozen policy SHA-256:
  `8904e6c9b844da08009f3f852353f884ab8602455418873e0e16c846d8efb288`.
- Implementation-gate SHA-256:
  `f7afd8263cc337d3ed9c4a3d907f16f54e463430dca6ef702694a645d21d3417`.

The full run remains FAILED under those identifiers. The old exact-argmax rule was
explicit in E0/P6. This is a deliberate amendment to that requirement, NOT a claim
that the old implementation was contrary to its specification.

## 2. What was checked here

Independent Python/NumPy/SciPy inspection verified:

- All **38 manifest-listed package members**, sizes and SHA-256 hashes.
- Both complete supplied **800-element QP-condition histories** against the
  existing P6 scalar rule. All 1,600 paired elements pass.
- The exact maxima, first maximizer indices, complete exact-maximizer sets, and
  reported binary64 values for the two failures.
- The two time arrays are identical within each supplied current/reference pair.
- Eight supplied selected 29-by-29 Hessian matrices are finite and symmetric;
  independent Cholesky factorization succeeds. Their smallest computed
  eigenvalues exceed 0.18. Corresponding matrices differ by at most
  `4.4408920985006262e-16`.
- Independent assembly from the supplied A, B, Q, R and slack weights, using the
  manuscript's scalar condensed QP, differs from the supplied selected Hessians
  by at most `1.1102230246251565e-16`. This is an independent calculation, not a
  replacement scientific producer or tolerance.

See `04_INDEPENDENT_CHECKS.json` for all values and the audit script for the
calculation. The stored MATLAB screen records say the selected matrices are
resolved and inside their condition envelopes. Those flags were inspected, not
re-executed in MATLAB here.

### Exact observed maxima

| Case | Mac maximum | Reference maximum | Absolute difference | First maximizer: Mac / reference |
|---|---:|---:|---:|---|
| K, amplitude 0.2 | 46751.520177057901 | 46751.520177057893 | 7.2759576141834259e-12 | 148 / 548 |
| K, amplitude 0.6 | 54492.811780144453 | 54492.811780144468 | 1.4551915228366852e-11 | 148 / 348 |

The maxima differ by **one and two binary64 spacings at these magnitudes**,
respectively. This is descriptive evidence, not a new ULP-based tolerance.

Their exact maximizer sets are:
- amplitude 0.2: Mac `[148,348,548]`, reference `[548,748]`;
- amplitude 0.6: Mac `[148,548]`, reference `[348]`.

The larger absolute differences anywhere in the two complete condition histories
are `5.8207660913467407e-11` and `8.7311491370201111e-11`. All history values pass
P6; acceptance is not being inferred solely from the two matching maxima.

At the reference's selected maximum, the Mac's loss relative to its own maximum
is 0 and `2.9103830456733704e-11`. At the Mac's selected maximum, the reference's
loss is `1.4551915228366852e-11` and `4.3655745685100555e-11`. Thus different
indices select values numerically indistinguishable at the already approved
reproduction resolution. No specific CPU/backend cause or exact periodic equality
is proved by these observations.

## 3. What MATLAB reports, and what remains unverified

The report records 262 implementation tests, 6 lifecycle tests, and a passed
49-check quick gate. The fresh full run then:

- completed and accepted all **535 Study 1 files / 258 controls**, with recorded
  Gram and claim-applicability qualifications;
- generated all **22 Study 2 controls**, with original validity checks passed;
- compared 45 of 46 Study 2 files: 44 passed and one failed at these two checks;
- did not process Study 2 `tables/run_metrics.csv` or execute Studies 3–6, P06,
  and the final fresh paper/figure gate.

Study 1 includes the noisy trials as well as its noise-free and legacy pilot
cases. It is not correct to say that the full run has tested no noisy cases.
The mixed-noise Study 3 campaign remains unexecuted in this fresh Mac run.

Reported partial-full counts are 579 passed / 1 failed out of 580 visited files,
86,651 Gram qualifications, 14,940 claim-applicability instances, and 910 retained
raw sign/interval differences. They are not whole-suite totals.

The report records 3,022 protected files / 1,357,579,926 bytes unchanged and a clean
source tree. I did not independently inspect those local protected bytes or the
live Git checkout. Complete trajectories, all Hessians, and the current full
`condition_parents` function are not supplied in this compact package. Its source
line attribution must be confirmed locally before editing.

The report retains runner elapsed time of 2,976.120 s and a UTC timestamp span of
66 min 6 s. Do not merge these into one invented timing explanation or a guaranteed
future runtime.

## 4. Why changing this requirement is justified

A maximum value and the identity of its maximizing sample are different outputs.
For arrays with nearly tied peaks, the maximum is numerically stable while its
first maximizing index can change discontinuously. MATLAB selects the first
occurrence of the computed maximum; it does not promise portable tie selection
when the computed array entries differ.

The attached paper checkpoint (`EJC_editorial_precision_annotated.pdf`, Appendix A,
pp. 51–52, Table A.14) reports condition-number maxima and counts. It does not make
a timing claim about these two maximizing samples. Before activation, check the
actual current manuscript/source claim map for any newer location-dependent
claim. A contradictory claim must be reported, not deleted to enable this rule.

We retain exact source membership and exact own-run reduction identity. What is
amended is **cross-machine equality of a derived, nonclaimed locator**, subject to
numerical agreement of the full history and the bound-derived consistency checks
in document 02. A locator used to trigger control, define an event, select a claimed
case, or support a timing claim is not covered.

This is not an expansion of the P7 unresolved-Gram treatment. All required QP
spectra and Hessian conditions must remain valid, resolved and within their
unchanged requirements.

## 5. Evidence limits and release consequences

This audit establishes the diagnosis and numerical eligibility for the supplied
fixtures. It does not establish all live parent bindings, all paper claims, later
study agreement, or a completed amended-verifier run.

Version the amendment, preserve the failed de77ad7 run, and retain actual producing
versus verifying identifiers. Do not claim the revised policy was fixed before
this failure. After diagnostic consolidation, a new tested candidate and effective
policy hash must be frozen before the final fresh Mac and Windows #2 verification.
P07 remains open; P08 independent confirmation remains separate.

## Primary reference

MathWorks, `max` documentation, accessed 2026-09-27:
https://www.mathworks.com/help/matlab/ref/double.max.html

The `[M,I]` behavior identifies the first occurrence of the maximum. The
project-specific agreement limits and claim applicability come from the approved
policy and manuscript, not from this documentation. The bound in document 02 is an
elementary consequence of the existing pointwise agreement inequalities.
