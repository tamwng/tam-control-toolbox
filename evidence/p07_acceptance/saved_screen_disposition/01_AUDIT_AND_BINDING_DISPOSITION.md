# Audit and binding disposition — P07 saved-screen blockers

## 1. Decision and status

Recommend approval of **two narrowly scoped screen-handling amendments plus implementation of the already approved P6 reporting comparator**. All normal integration/validation gates remain in force. This is not a PASS verdict for the incomplete verifier or for an unexecuted reproduction campaign.

Source reviewed: `P07_REVIEW_BRIEF.zip`, SHA-256 `4acaa720ce4ea3d0af0bb8728270612c72e692d6045d25880094f45a2fb5069e`.

Reported base HEAD: `75251c47d8c6ffd1806b84d7781ba35a0c2cba61`.
Reported inactive policy: `P07_PORTABLE_20260926_V2`, SHA-256 `11299f699e4eb7965e4fef5698f71e8bef4b126d1a3f2f8c2d6a9e2e18bf639e`.

The brief reports 2,073 saved control cases screened; twelve blocking matrix instances; ten other intermediate-rank instances eligible at the single-matrix stage; 49/50 distinct tests passed; no fresh quick/full execution and no candidate commit. It reports unchanged paths, sizes, and hashes for 3,022 protected records. The full current source patch is retained on the user's Mac rather than contained in this brief; I have not independently inspected the live repository or run MATLAB.

Implementation is still incomplete: the brief identifies 59 CSV families and integrated runner/lifecycle dispatch remaining. These must be finished and checked before commit; fixing twelve classifications alone is not sufficient.

## 2. Independent checks actually performed here

- Verified all 24 manifest-listed file sizes and SHA-256 values.
- Loaded all 22 selected matrix fixtures from MAT, and checked exact binary64 agreement with their JSON matrix views. Used MAT for nonfinite values; JSON nulls were not treated as zeros.
- Recomputed singular values/rank with NumPy/SciPy on the supplied matrices.
- Recomputed symmetric-matrix singular values as absolute eigenvalues of the **exact stored binary64 entries** at 80 and 120 decimal digits with mpmath.
- For all ten full-rank-boundary blockers, the independent point threshold ranks agree with the Mac-reported values at tau=1e-10. Of these ten, five point calculations are threshold-full-rank and five threshold-deficient. They must not all be described as deficient.
- The two Study 5 matrices are exactly all-zero 2-by-2 arrays. Their retained original ranks are zero and stored condition values are +Inf; each has one completed regressor row. The brief's local checks report matching formation/decomposition. Parent regressor rows are not supplied here, so the implementation must independently verify exact zero parent rows before using the zero branch.
- The reporting test log isolates two covariance-condition maximum differences: -4.2632564145606011e-14 and +1.4210854715202004e-14. These are far inside the existing P6 scalar target, but parent validity/source/extremum checks remain required.

The arbitrary-precision calculation is a numerical cross-check of the frozen fixtures, **not** an interval certificate, a replacement oracle, or proof that future Mac/Windows trajectories/ranks agree. Do not add a symbolic or mpmath dependency to the MATLAB release for this decision.

## 3. What the twelve blockers mean

Seven P06 complete-quadratic instances and three Study 4 affine instances fail an additional robustness-margin screen: its chosen envelope intersects the numerical-rank cutoff. This demonstrates that the *screen cannot certify that classification against its entire chosen perturbation envelope*. It is not an observed mismatch between a fresh run and its reference. The original engineering envelope is explicitly not a rigorous interval proof.

Two startup Study 5 instances are exact zero Grams. An all-zero nonempty matrix has rank zero. The broad floating-point screen's subnormal positive eta artificially leaves [0,n] possible; that is not the appropriate way to classify an exact structural zero.

The verification objective is numerical reproducibility of the specified calculation, with preserved scientific ranks/counts and conclusions. It is not a newly imposed theorem that every passive rank diagnostic stays unchanged under every perturbation allowed by a conservative envelope.

The distinction below is a **change to the qualified-acceptance claim**, not a claim that formerly unresolved raw condition numbers have become equal. Preserve that qualification explicitly.

## 4. Invariants: these do not change

- Scientific algorithms, control/estimator code, seeds, settings, scaling, raw records, and reference outputs.
- All existing author-approved numeric atol/rtol constants, finite masks/signs, applicable source bindings, statistical requirements, and the original P06 baseline gate.
- tau=1e-10; rho=100*n*eps; eta, formation/decomposition and condition-resolution formulas for nonzero matrices.
- Original producer rank/validity fields and their definitions, count/argmax/selection/threshold outcomes and publication checks. MATLAB default rank, declared threshold rank and algebraic rank remain different concepts.
- No clipping, diagonal jitter, rescaling, eigenvalue replacement, reference regeneration or broader near-tie exception.
- No waiver for RLS covariance or QP Hessian validity/conditioning.
- The same nineteen passive raw-Gram history/summary scopes, SHA-256 `d8cceaa07496ecc87ab852f3095ffc9f7dc73dfab34791a26500e6d0524c077d`.

## 5. Amendment Z — exact zero Gram

Add a verification-only branch for a nonempty, real, finite Gram matrix **all of whose entries are exactly zero**. Before admitting it, verify:

1. Correct class, dimensions, normalized coordinates, source record, and completed-row count m>=1.
2. The corresponding own-run normalized regressor matrix has **all entries exactly zero**, with the expected nonempty row selection. This prevents classifying an underflowed product of nonzero rows as a structural zero.
3. Existing formation/decomposition and source checks pass. No covariance or Hessian can use this branch.
4. The original producer ranks, flags and finite/nonfinite masks retain their documented meaning. For the supplied fixtures original rank=0 and raw condition=+Inf. Read the MAT values, not JSON nulls.

Record `STRUCTURAL_ZERO_GRAM`, point rank=0, supplemental rank interval=[0,0], and the actual singular-condition convention. Do not perform Inf-Inf subtraction as a numeric equality test. Compare the nonfinite mask/sign explicitly under the existing rules. Do not turn NaN into Inf, remove a record, substitute zero, or claim a finite condition value.

For a paired fresh/reference comparison, **both** must satisfy the exact structural-zero prerequisites, with matching source/row semantics and original masks/flags. A zero versus merely tiny nonzero pair does not automatically pass. It follows existing exact/mask/rank requirements and blocks if they fail. A zero stored G with any nonzero parent regressor also blocks for investigation.

This resolves the exact-zero special case; it does not enlarge numerical tolerances or supply a zero-matrix waiver to other matrix types.

## 6. Amendment B — supplemental smallest-rank boundary in passive P7 diagnostics

Keep the previous resolved-rank and robustly deficient intermediate-rank paths. Add only the following branch for the **same nineteen P7 raw-Gram condition scopes**:

At single-matrix preflight, a nonzero matrix can be `ELIGIBLE_P7_FULL_RANK_BOUNDARY` if:
- all source, shape, finiteness, normalized-regressor, formation/decomposition and required spectral checks pass;
- the raw condition is unresolved under the existing resolution rule, not resolved-but-outside-envelope;
- the supplemental interval is [n-1,n], i.e. uncertainty is only whether the smallest singular value clears the cutoff;
- the smallest singular value exceeds eta, the existing finite condition envelope exists, and all applicable own stored/recomputed raw condition estimates lie inside that envelope. An unresolved *width* is permitted; an estimate outside the finite envelope is not;
- original scientific ranks/validity/counts, where present, satisfy their existing requirements;
- the field is a passive diagnostic, not used to control estimation, optimization, accept/reject logic, experimental selection, or another mandatory scientific outcome.

Keep the point rank, full interval, eta, singular values, margins, raw condition values/masks, and existing checks in the report. Keep `rankResolved=false` where appropriate; do not relabel an interval endpoint as a certified scalar rank. A stored matrix with no original rank must remain explicitly missing that original field. Do not invent historical rank data.

At the **paired** stage, qualification requires:
1. Both sides satisfy their applicable valid-matrix/resolved-or-eligible branch, with at least one admissible unresolved P7 condition. If both conditions are resolved, apply the ordinary P6 numeric rule; a normal resolved failure is not eligible.
2. The actual parent matrices and regressor records agree under unchanged P5 and existing parent rules.
3. Their nominal supplemental point ranks at tau=1e-10 match **exactly**, and their supplemental intervals overlap. Where a side is rank-resolved its interval is the singleton rank. This does not assert perturbation-invariant rank.
4. All original scientific rank values, rank-derived counts/ranges/fractions, validity flags, masks/signs, outcomes, exact selections, and publication checks pass under the pre-existing requirements. A fresh original-rank mismatch still blocks. The same applies to unequal supplemental point ranks.
5. No required claim relies on equality of the unresolved raw condition or on robust full-rank/deficient status that the envelope does not establish. Such a required claim is not verified by this branch.

Use a visibly distinct verdict such as `QUALIFIED_PASSIVE_GRAM_BOUNDARY_POINT_RANK_MATCHED`. This means reproducible mandatory quantities with an unresolved passive raw condition and supplemental margin; it does **not** mean the raw condition number has reproduced within tolerance. Preserve and count every qualified instance and propagate the qualification through passive reductions and the top-level report. Do not change original scientific MAT/CSV fields or silently score their unresolved raw extrema as reproduced numbers.

A range broader than [n-1,n] with full rank possible, a failed formation/decomposition, unequal actual point/original rank, changed scientific count/outcome, unlisted/active field, prohibited mask change, or unresolved required covariance/Hessian remains blocking. No file-name or sample-index whitelist is authorized. The ten supplied instances are fixtures for testing the rule, not exceptions by name.

This removes a supplemental robustness-certification demand for the defined passive branch while retaining **actual paired numerical-rank agreement** and the paper's rank/count statements. It does not promise that those actual comparisons will pass after the new runs.

## 7. Reporting oracle — integrate P6, do not introduce a new tolerance

The brief's single failing test is `test_p07_reporting/testSeparateStudy1SummaryMatchesPreinterfaceOracle`. The log reports only two differences in `diagnostics.covarianceConditionMax` at about 1e-14.

Explicitly authorize the minimum verification-only amendment to this assertion (or its active portable test wrapper) so that this field follows the already approved P6 rule:

    abs(actual-reference) <= 1e-8 + 1e-7*abs(reference)

Require all applicable P6 matrix/decomposition/resolution, own-source reduction, mask/count and argmax safeguards as already specified. Preserve strict checks for the remaining exact fields; other computed fields may use only their previously approved mappings. No blanket tolerance on the enclosing struct and no ignoring the failed test.

Keep the old strict-failure log and frozen pre-edit test content. The newly amended portable test is a **new execution under the stated rule**, not a retrospective pass. Add tests that a larger-than-budget discrepancy, changed count/schema/mask/source, or invalid parent matrix still fails. If the old test is retained separately as a bitwise diagnostic, it may report strict inequality, but the active portable suite must actually execute and pass the approved fieldwise assertion; do not mark the test skipped/incomplete as a substitute.

This authorizes a narrow test-infrastructure edit; it does not authorize changing `study1_summarize`, covariance producers or saved expected numbers.

## 8. Implementation, cache use, commit and execution

- Retain the reviewed in-progress verification files; do not reset the repository. Update only verifier helpers/dispatch/policy/tests/docs in the prior allowlist, plus the specifically authorized test assertion above.
- Keep the user-approved `*.DS_Store` ignore entry. The deleted metadata file is not recreated. No further cleanup is authorized.
- Preserve V1/V2 policy snapshots and historical failed attempts. Use a new policy ID (for example V3) and report the exact new hash.
- Complete the remaining 59 CSV families, unit/source dispatch and lifecycle tests. The current 49/50 count is not final coverage. Do not launch from a partial verifier.
- To avoid re-generating large redundant diagnostic archives, unchanged formation/decomposition facts may be reused from saved screen artifacts only when bound to the exact source/matrix/parent hashes, checker version and unchanged numeric constants. Explicitly label reuse and apply the new classification/paired dispatch separately. Recompute where those dependencies cannot be established. Test changed branches anew. No cache can replace a fresh trajectory in the actual reproduction run.
- After all mandatory implementation tests, bindings, original scientific validity, integrity, and saved-data gates pass with only permitted reported qualifications, create the frozen local candidate commit. Then rerun tests and Mac quick from that candidate; if accepted, proceed to Mac full on the same policy/commit without another approval round.
- Stop on an actual failure. Do not change a numeric rule mid-run. Collect independent failures into one report where safe. Do not promise that a still unexecuted suite will pass.
- Return compact checks and manifests, not the full raw archive. Distinguish strict equality, numeric agreement, qualified passive diagnostics, and failures in the summary.

## 9. Reporting and cross-machine boundaries

No paper, reviewer letter, or scientific result changes are authorized now. Once reproduction really succeeds, the paper can accurately describe the source revision, numerical acceptance protocol and machine coverage, with detailed qualified-diagnostic rules in repository documentation. Do not imply exact raw Gram-condition equality or universal platform independence.

A historical Windows #1 dataset can remain the reference if scientific-source provenance is established; it is not a fresh run of a new verifier commit. After Mac succeeds, Windows #2 can reproduce the same frozen candidate. A claim that *all three machines executed that final commit* would require three such executions. Subsequent pedagogical refactoring must itself receive verification before a final release identifier is reported.

P07 remains open until the actual required runs and release work are completed. P08 independent-confirmation status is a separate question; replaying fixed inputs/seeds on another computer does not establish it.

## 10. External technical context

These primary sources support the definitions, not the author-selected constants or exceptions:
- MathWorks rank: singular-value counting above a specified tolerance; default and custom tolerances differ. https://www.mathworks.com/help/matlab/ref/rank.html
- MathWorks cond: largest/smallest singular-value ratio and Inf convention for a singular matrix. https://www.mathworks.com/help/matlab/ref/cond.html
- LAPACK Users' Guide, SVD error bounds: approximate floating-point error context. https://www.netlib.org/lapack/lug/node96.html

No stronger theorem or independent campaign verification is inferred from those sources.
