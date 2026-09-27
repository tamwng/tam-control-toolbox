# Mac MATLAB — implement the approved policy and execute through gates

## Authority

I approve the consolidated P07 acceptance policy, subject to every binding clarification in `01_AUDIT_DECISION.md` of this attached handoff. Implement those decisions now; do not produce another policy-only proposal or request individual approval for P1–P13.

Use your existing `P07_CONSOLIDATED_ACCEPTANCE_POLICY_REVIEW.zip`, verified against the SHA-256 in the audit decision. Keep it immutable. The original quick failure remains a historical failure; do not relabel it.

The objective is numerical reproduction under ONE frozen policy and candidate SHA, later tested on the Mac and two Windows machines. It is not bitwise identity of all computed values and not proof of portability to every platform.

## 1. Read-only preflight

Confirm base commit `75251c47d8c6ffd1806b84d7781ba35a0c2cba61`, tracked source hashes, the exact protected-reference inventory, and existing failed/paused artifacts. Confirm no newer work conflicts with this baseline. Treat only the disclosed untracked `results/.DS_Store` as the metadata exception authorized by the audit; leave it untouched and report it. Do not use `git clean`, reset, broad ignores, or hidden-change flags.

Keep all outputs in new, uniquely named areas under the repository's existing authorized output convention. Do not overwrite previous attempts. Keep review exports compact; bulky raw records stay local.

## 2. Permitted implementation

Make only the minimum verification changes in:
- `run_ejc.m`: profile dispatch, explicit gate orchestration, provenance, reporting.
- `studies/p07/ejc_compare_results.m`: scientific comparison and verdict dispatch.
- `studies/p07/ejc_paper_report.m`: comparison/assertion/verdict handling only.
- `ejc_validate_sources.m`: validation of fresh parents/policy/eligible verdicts.
- The existing `tests/test_p07_comparison.m`, `tests/test_p07_entrypoints.m`, and `tests/test_p07_reporting.m` where required for this verifier.

New P07-only comparator/policy/helpers, small fixtures, tests and documentation are allowed in the reviewed plan's P07/test areas. Keep one shared policy implementation for quick/full/reporting. Preserve the old strict profile for comparison; add the portable profile explicitly rather than erasing strict results.

Scientific `src` algorithms, Study 1–6/P06 numerical producers, seeds/configurations, solver options, experimental selections, plotting calculations, historical MAT/CSV outputs, and manuscript sources are NOT editable. No repository-wide refactor, renaming or README cleanup in this pass.

A1–A5 retain their approved limits. Implement all approved P1–P13 limits, unit/row predicates, exact guards, CSV source contracts and qualified Gram scope. Follow the audit's copy-vs-cross-run, P06-gate-residual, publication, metadata and storage clarifications. Do not choose bounds from observed differences.

Validate source bindings from actual producers, not field names. Complete column-specific bindings for the 84 CSV families as implementation work. Do not request approval merely to fill an unambiguous existing source/subscript/reducer mapping. A genuine ambiguity, changed scientific meaning, or an additional protected-file modification still requires STOP AND ASK.

## 3. Implementation gate — before committing or simulations

Freeze the approved policy constants in the implementation, with a stable ID such as `P07_PORTABLE_20260926_V1`; record its content hash. Store the runtime candidate SHA in output provenance, not as a self-referential tracked file edit.

Test ALL rule families, not only the already tested A1–A5 arithmetic:
- exact configuration/record/schema/copy/outcome checks and 24 narrow historical omissions;
- every unit-aware scalar/array bound, including inside/on/outside, zero, sign, class, shape, NaN/Inf and required/not-applicable cases;
- matrix formation, decompositions, symmetry/positivity, resolved conditions, approved unresolved Gram cases and rank-boundary rejection;
- precedence for A1–A5, source-based copy dispatch, P06 baseline residual reporting;
- CSV delimiters/Windows paths, row predicates, confirmed precision and source linkage;
- statistic signs/interval zero inclusion and published-claim flags;
- fail/qualified/unresolved propagation in quick/full/paper and fresh-parent validation;
- no silent NaN acceptance, missing fields, generic float fallback, reference substitution or scope widening.

Run saved-record checks and the tiny Gram fixtures. Do not claim these are fresh campaign results. Check the full source diff and protected hashes. Implementation bugs may be fixed within this allowlist before the candidate is frozen, without another policy proposal. Do not alter the numerical requirements to make a test pass.

If all implementation checks pass and changes are confined to the allowlist, create ONE local verification-candidate commit. Commit only the intended sources/tests/policy/docs, not raw outputs, historical archives, incidental metadata or unrelated changes. This prompt explicitly authorizes that local commit; no push/tag/publication is authorized.

## 4. Mac quick gate and full suite

From the frozen candidate, rerun the comparator/entrypoint/report tests, then the existing quick workflow with the approved portable profile. Record the exact candidate SHA, policy hash, environment/BLAS/LAPACK/thread and solver configuration. Preserve every old analytical/scientific-validity check and the quick fixed-record checks.

If these gates succeed with no failed mandatory checks and no unapproved unresolved scopes, continue to the full Mac workflow in the same task. No additional approval round is needed after a successful gate. A fully justified, explicitly counted P7-only qualification is eligible to advance; never rename it an unqualified equality pass.

Full execution retains the reviewed sequential study order, existing P06 baseline gate and aliases. Recompute Studies 1–5/P06 and derive Study 6 only from the fresh accepted parent outputs under this same candidate/policy. No historical fallback parent.

Preserve the expected coverage: 2,877 scientific output files, 2,073 control cases, 329 Study 6 diagnostic batches and 24 declared legacy omissions, interpreted through the existing manifest contracts. Run the paper-result extraction/consistency checks; do not edit any manuscript.

Do not wait for Windows before completing these Mac-local gates and full run. Windows evidence is still absent and must remain labeled absent. Each Windows machine will execute its own verifier tests -> quick -> full on exactly this candidate/policy. The small Windows matrix probe will be returned separately.

## 5. Failure handling and output

A real source/policy/hash mismatch, failing numerical/validity/claim check, unsupported unit or unresolved producer stops the current gate. Preserve outputs and give one consolidated report of known failures. Do not auto-retune, relax thresholds, change seeds, change references, retry to get a favorable result, or modify frozen code during a campaign. Any later code fix creates a new candidate and invalidates using the old reports as tests of that new SHA.

At completion, return `P07_MAC_PORTABLE_VERIFICATION_REVIEW.zip` containing:
- the minimal source diff/commit manifest and exact candidate SHA;
- frozen policy plus hash and explicit approved scope;
- implementation/comparator test reports;
- fresh quick report and, only if run, full report;
- exact/numerical/qualified/failed/unresolved counts and worst discrepancies with units/case/field/index;
- complete compact index of qualified Gram cases and their checked parent/rank/formation/decomposition results;
- CSV/source-binding and paper-result reports, including explicit unrounded-data or manuscript-claim limitations;
- protected/source integrity and literal git-status records;
- environment, runtime, raw-output manifest and explicit Windows MISSING status;
- exact working commands for the two Windows machines, using this candidate and policy.

Large trajectories remain local. Do not return another 4,195-row narrative in chat. Give a summary of no more than ten lines identifying the actual stage reached and the next external action. Do not declare P07 closed; final multi-machine verification and the later pedagogical release remain separate. P08 is unaffected.

Then STOP. Do not start the pedagogical cleanup, edit LaTeX, submit, push or tag.
