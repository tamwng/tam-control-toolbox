# P07 — Bind the two Study 3/4 condition-consistency assertions to the approved portable rules

## Decision

Implement this narrowly scoped verification-binding amendment. This is authorization to finish the verifier, not a declaration that the saved-data gates or fresh reproduction have passed.

The numeric constants, rank thresholds, scientific algorithms, experimental configurations, and historical outputs do not change. The only newly authorized acceptance substitution is at the two stored-versus-independently-reconstructed **recent-Gram condition** consistency assertions identified in `01_AUDIT_AND_DECISION.md`.

Read that decision and `02_REQUIRED_CHECKS.md` first. Keep the approved index-2 correction and its negative tests. Preserve the original quick FAILED status, strict-assertion failures, previous policy snapshots, and all protected records.

## Implementation boundary

Prefer a P07-only adapter that executes every other original Study 3/4 check. A wrapper that merely catches a generic assertion exception, returns early, skips the rest of a verifier, or marks a skipped test passed is prohibited.

If a true adapter cannot reach the remaining private checks, this authorization ALSO permits a minimal optional comparison callback/mode in:
- `studies/study3/study3_verify_results.m`;
- `studies/study4/study4_verify_results.m`.

Keep the no-option/default path exactly strict, including its existing constants. Propagate the optional callback only far enough to replace the named Gram-condition comparison. Pass the actual stored scalar, independently reconstructed scalar, both matrix parents, original row/index/source semantics, and the required check results. Do not change the shared general-purpose `close` helper or any other assertion. Do not duplicate the scientific verifier or its metric calculations.

These two verification-source hooks, their P07 adapter, tests, dispatch, and policy-binding documentation are explicitly permitted. Do not request another approval solely because these named verifier files need that minimal hook. Scientific producers, controller/estimator code, baseline data, and unrelated files remain protected.

## Rules to reuse — no new tolerance

Apply the already approved matrix formation/decomposition, parent, spectral, source, rank, mask/sign, count, validity, outcome and publication requirements.

- Screen-resolved finite conditions: each value must satisfy its own parent-matrix envelope; apply the existing policy-family P6 comparison `abs(actual-reference) <= 1e-8 + 1e-7*abs(reference)`, with the historical stored scalar as reference. A resolved mismatch beyond this bound remains BLOCKED.
- Admissible unresolved passive Gram conditions: use the existing amended policy-family P7 logic only. Preserve matching nominal ranks, original ranks/counts/flags, appropriate overlapping supplemental intervals, admissible own envelopes, and all other guards. Report the qualified diagnostic; do not claim ordinary numerical equality.
- Preserve the existing explicit structural-zero and valid rank/Inf conventions. Do not add blanket equality of infinities/NaNs or change nonfinite masks.

Here P6/P7 are **policy-family names**, not permission to reopen research tasks P06/P07.

Apply these rules to every applicable instance at the two named assertion sites, not just the supplied fixtures or already failed indices. The corresponding raw-field scopes are F0894 (Study 3) and F1344 (Study 4). This extends their comparison context to same-record reconstruction; it does not add other fields to the passive scope.

Do not infer PASS from source identity, matrix agreement alone, or a check result initialized to true. Execute required checks or use explicitly hash/version-bound reusable results under the previously approved cache rules. Missing/incomplete required checks block acceptance.

## Complete and execute

1. Preserve the pre-edit verifier sources and failures. Record this binding amendment in a versioned policy annex/new policy identity. Keep previous policy bytes; publish the effective hash even though numeric limits are unchanged.
2. Implement the named adapters/hooks and positive/negative tests, preserving default strict behavior.
3. Finish the complete original-plus-portable Study 3/4 validation, remaining 9,231 applicability/parent/qualification entries, full/paper dispatch, and lifecycle integration. Counts in the brief do not constitute full coverage.
4. Rerun the complete implementation test suite after the final parser/adapter changes. Report every requirement as executed PASS, explicitly qualified, FAIL, or genuinely not applicable; do not count skipped/incomplete as PASS.
5. Recheck source differences and all 3,022 protected archive entries against their unchanged manifest. Verification-source changes must be disclosed separately from scientific-source identity.
6. If ALL mandatory implementation/saved-data/integrity gates pass with only approved recorded qualifications, create the frozen local candidate commit. Run Mac quick from that commit; if accepted, run Mac full on the same commit and effective policy. No additional approval round is needed for that already authorized sequence.
7. If a real blocker remains, collect independent failures where safe and return ONE compact report. Do not alter the rules mid-run or claim the suite will pass in advance.

Do not push, tag, edit LaTeX, perform repository pedagogy cleanup, or claim P07 closure/P08 confirmation.

Return the compact review ZIP with the diff, policy/source hashes, strict-failure ledger, portable assertion ledger and totals, final tests, CSV/full-dispatch completion status, archive integrity, candidate identity if created, and actual quick/full outcomes. Keep full trajectories and large instance ledgers locally with hashes and locators. Then STOP.
