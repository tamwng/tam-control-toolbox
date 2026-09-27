# P07 Study 3/4 diagnostic-consistency binding — audit and decision

## 1. Decision

Approve a narrowly scoped portable replacement for the two original recent-Gram condition consistency assertions, while retaining their strict default behavior and every other original check. The existing P6/P7 policy families supply the numerical/qualified comparison; no new numeric tolerance or rank exception is introduced.

This is an explicit change in which verifier requirement controls portable acceptance at these two sites. It must be versioned and disclosed. It does NOT make the original failed assertions pass retrospectively. It does not declare fresh Mac/Windows results equivalent.

The index-2 Inf correction is consistent with the supplied producer semantics and previous intent. It remains a documented qualified passive diagnostic, not a blanket Inf equality primitive. Do not reopen it without a specific contrary finding.

## 2. Material actually checked

Input: `P07_GRAM_DIAGNOSTIC_BRIEF.zip`.

The audit verified the size/SHA-256 of all 28 files listed in its package manifest. The source report, status summaries, patch, targeted regression source/logs, and three selected matrix/regressor fixture pairs were inspected. Independent NumPy/SciPy and 80-decimal mpmath calculations used the saved binary64 matrices, not rounded JSON renderings.

Not independently executed or inspected here: MATLAB, the live working tree, all 3,022 protected archive entries, the full 69,771-row failure ledger retained locally, or the unfinished full/paper verifier. Source hashes establish identifiers in the package; they do not substitute for reading/executing the live source. The full current Study 3/4 verifier bodies are not in this brief. The exact assertion sites and formulas below come from its documented traces and must be matched locally before editing.

The independent calculations are in `03_INDEPENDENT_FIXTURE_CHECKS.json`; the script and original fixtures are supplied for traceability. They are audit diagnostics, not a replacement implementation or a new gate.

## 3. Findings

### Corrected exact-singular index 2

Both fixture matrices are diag(1,0,0), with one normalized regressor [1,0,0], source counts one, point rank one and a positive infinite raw condition result. The reported missing `gramRank`/`gramValid` fields follow the original Study 1 producer; inventing those fields was not a valid prerequisite. The submitted patch identifies the raw-singular producer path and retains additional guards. The report gives 23/23 targeted tests. This does not imply that unrelated nonfinite values agree or that the new quick gate ran.

### Original Study 3/4 failures

The report locates the failures at:
- Study 3 `check_run`: the `gramCondition` consistency comparison at approximately line 199, using the general strict `close` assertion around line 283; budget `1e-12*max(1,abs(recomputed))`.
- Study 4: the finite-full-rank `gramCondition` consistency comparison at approximately line 94, using the strict `close` assertion around line 155; budget `1e-6*max(1,abs(recomputed))`.

These are checks of a diagnostic scalar recomputed from stored run data. They are not fresh controller executions. The reported scan covers 211,024 applicable Study 3 Gram instances and 10,791 Study 4 instances. It records 69,768 and 3 condition-comparison failures respectively, with zero failures in the separately scanned original matrix/rank/count/validity requirements. These are author-department scan results, not independently rerun totals.

Independent selected-fixture findings:

| Saved pair | Relative scalar discrepancy | Approved P6 bound ratio | Parent/rank result | Appropriate route if every other live guard passes |
|---|---:|---:|---|---|
| Study 3 abrupt_A_none_000, index 54 | 1.288e-12 | 1.288e-5 | Matrices differ by at most 1.11e-16; both point ranks 3; envelopes screen-resolved | Ordinary P6 numerical agreement |
| Study 3 abrupt_A_fixed_000, index 888 | 1.465e-6 | 14.65 | Matrices differ by at most 4.44e-16; both point ranks 3; rank intervals [3,3], but condition envelopes unresolved | Existing P7 unresolved-condition qualification; NOT ordinary P6 agreement |
| Study 4 no_change_A, index 61 | 2.249e-6 | 22.49 | Matrices differ by at most 4.44e-16; both point ranks 3; supplemental intervals [2,3] | Existing amended P7 full-rank-boundary qualification; NOT ordinary P6 agreement |

All three pairs have exactly matching producer-style versus verifier-style regressor arrays in the supplied fixtures. Both matrix parents pass the existing engineering formation screen in our calculation. Their stored/reconstructed scalars lie inside their own existing condition envelopes. The high-precision calculation of each exact binary64 matrix also gives point rank 3 at tau=1e-10. No historical scalar is replaced by that calculation.

For the two high-condition pairs, the proposed ordinary finite bound does NOT pass. The appropriate treatment is the already authorized, explicitly qualified passive-condition branch, subject to its full guards. It would be incorrect to report that every diagnostic value agrees within tolerance.

These checks support sensitivity of the computed condition diagnostic. They do not establish a specific OS, CPU, or BLAS as its cause; differences also arise between two matrix-formation paths on saved data. No new trajectories have been compared in this return.

## 4. Why this is a principled binding change

The existing portable design already checks the matrix, formation from the original regressors, decomposition, scientific rank/count semantics, and resolution of the condition diagnostic. Leaving an additional legacy scalar-equality requirement active at a tighter fixed precision can reject that same valid portable result before subsequent checks run.

The correction is to bind both named assertions to the same approved rule, not repeatedly enlarge the two legacy tolerances. It preserves the original strict regression mode as a separate diagnostic. It does not discard independent reconstruction or skip the remaining verifier.

A correct condition diagnostic depends on its matrix and very small singular values. Equality of the diagnostic to a nearly machine-precision relative budget is not equivalent to agreement of the underlying scientific computation. Conversely, matching ranks alone is insufficient: parent, formation, decomposition, source and outcome requirements still apply.

The author-selected resolution envelopes are engineering screens, not certified error bounds. Independent high-precision fixture calculations support the present diagnosis but do not certify every saved instance or justify new thresholds.

## 5. Binding authority and safeguards

The extension applies ONLY to the stored-versus-independently-reconstructed recent-Gram condition comparisons at the two named sites, linked to existing P7 scopes F0894/F1344. It applies by field/source semantics to all their instances, not by a whitelist of successful cases.

For each comparison:
1. Preserve original formation/scaling/window indices, row counts, validity, stored/independently recomputed scientific ranks and nonfinite semantics. Execute every other original numerical assertion unchanged.
2. Apply all relevant approved P4/P5 parent and spectral checks and unchanged formation/decomposition screens. Both scalars must retain their own matrix and source lineage; do not substitute a convenient matrix or new scalar.
3. If both conditions are screen-resolved and finite, require their own envelopes and the existing P6 numerical agreement rule: abs(actual-reference) <= 1e-8 + 1e-7*abs(reference). In this same-record context the original stored scalar is the reference. Failure beyond this rule remains blocking.
4. If an admissible passive condition is unresolved, use existing amended P7 qualification only. Matching original/nominal point ranks, permitted supplemental intervals, own envelopes where required, matrix/regressor/spectral agreement and publication/outcome requirements remain mandatory. Keep unresolved raw values visible in all derived reductions.
5. Inf/zero/mask handling follows the approved, producer-specific branches. Neither matching Inf values alone nor a large condition value alone grants acceptance.
6. Do not qualify covariance/Hessian conditions, actual rank/count/mask disagreements, invalid parents, unlisted/active diagnostics, or changed scientific findings.
7. Do not claim the 69,771 previously failing instances are now accepted until this adapter has actually classified every applicable instance and completed the remaining checks.

## 6. Permitted implementation strategy

The target is one shared numerical policy with narrow bindings, not accumulating independent tolerance systems. A P07 adapter is preferred only if it preserves execution of all other original requirements. Catching the first generic assertion exception and calling the whole study verified is prohibited.

A minimal optional callback/mode in the two verification `.m` files is expressly allowed if needed. Existing entry calls keep the original strict branch and formulas. Only the named condition comparison uses the callback during P07. Parameter propagation and return of its qualified status are allowed; substantive refactoring, edits to shared `close`, other numeric comparisons, producers, algorithms or archived records are not.

Provide a one-to-one assertion-coverage/diff check; prove through injected errors after the former stopping point that the portable path runs the rest of each verifier. Retain old source/failure logs. See `02_REQUIRED_CHECKS.md`.

## 7. Identity, execution and reporting

Reported HEAD: `75251c47d8c6ffd1806b84d7781ba35a0c2cba61`.
Reported inactive effective policy: `P07_PORTABLE_20260926_V3`, hash `eccd22c35977224d2965b4eb45684af4dafdf5c666d5f34149406ba5f9914fee`.

Retain that policy snapshot. Record this explicit assertion-binding change in a new versioned annex/effective identity/hash; numeric constants remain unchanged. New quick/full execution must use the subsequently frozen candidate and that complete effective policy. Do not claim policy identity remained unchanged merely because its constants did.

The reported 191-test suite predates the final CSV parser optimization. The six parser regressions, 445,112 scalar checks and 4,760 contrast checks are useful but do not complete the other 9,231 pending entries or full/paper dispatch. Rerun final integrated tests after the adapter and parser are finalized.

After successful complete integration and saved-data gates, the existing authorization remains: candidate commit, Mac quick, then Mac full if quick is accepted. Stop on an actual mandatory failure. No guarantee is made that all remaining checks will pass.

Keep historical Windows reference results distinct from fresh Mac/Windows #2 reproduction. Defer paper wording until actual execution and final reproducibility release. This is P07 verification infrastructure only, not P08 independent confirmation or permission for repository pedagogy cleanup.

## 8. Primary technical context

These sources support numerical definitions and limitations, not approval of particular constants:
- MathWorks, cond: https://www.mathworks.com/help/matlab/ref/cond.html — the 2-norm condition is the ratio of extremal singular values; singular matrices have infinite condition.
- MathWorks, rank: https://www.mathworks.com/help/matlab/ref/rank.html — numerical rank counts singular values above the declared tolerance.
- LAPACK Users' Guide, SVD error analysis: https://www.netlib.org/lapack/lug/node97.html — backward-stable SVD need not give high relative accuracy in the smallest singular values.
