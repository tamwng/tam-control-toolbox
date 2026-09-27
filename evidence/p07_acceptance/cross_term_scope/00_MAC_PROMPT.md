# Mac — bounded cross-term claim-scope amendment and continued verification

Read `01_AUDIT_AND_BINDING_DECISION.md`. This is a narrow post-failure amendment to claim applicability, not a new numerical-tolerance proposal.

## Frozen failed baseline

- Producing/verification candidate C0: `894eba817eaa43b882f849c5f830f64a8d6dbe39`.
- Policy SHA-256: `05c20f48e37a352f62ad3fb8975b7803be10ecd9e528bfeff61ac5005c97c451`.
- Full run: `results/p07_mac_full_894eba8_20260927_01`.
- Original outcome: FAILED after Study 1; preserve it and every log/result.

I approve the scope correction in the binding decision. Do not change scientific code, numeric acceptance limits, rank thresholds, Gram rules, settings, seeds, fitting/control/reduction algorithms, reference values, or scientific results.

## Implement and test

1. Confirm the failed package's identities and the protected source/data manifests. Do not edit a working tree used by an active Mac or Windows MATLAB process.
2. Separate source-verified descriptive algebraic cross terms from explicitly asserted directional claims. Do not apply generic exact sign equality merely because a descriptive `meanCrossTerm` is signed.
3. Use `04_SCOPE_CANDIDATES.csv` to bound the existing fields; verify actual source definitions and manuscript applicability before activating a mapping. Keep the same rule for all comparable rows, not only failed row indices.
4. For descriptive diagnostics, retain unchanged P10/P11 numeric, parent/source, unit, validity and decomposition requirements. Retain raw signs and discrepancies. Record `NUMERICAL_AGREEMENT_SIGN_NOT_ASSERTED` when applicable, never exact equality or a proved zero.
5. For explicit scientific claims, retain their existing sign/order/interval guards. Leave all non-cross-term performance contrasts, discrete outcomes, sign conventions and CI checks unchanged. Derived cross-term P11 rows are covered only by the exact metadata/source rules in the binding decision.
6. Add the specified positive/negative regression tests, run the entire verifier/prerequisite suite, and audit the diff. Do not globally relax `ejc_claim_check` or use an assumed true-zero cutoff.
7. Revalidate all 535 saved Study 1 scientific files and original stage requirements, including the eight previously unprocessed files. Read only the existing generated arrays/tables; do not rerun trajectories to repair comparisons. Use a new verification output directory and preserve the old failed run.

If a required claim/source mapping is ambiguous, or a mandatory numeric/identity/outcome check fails, preserve and report the cause. Do not silently exempt it. Collect independent non-destructive check failures together where safe.

## Freeze and execute

If all implementation, integrity and saved-data gates pass:

- create a NEW frozen local candidate commit C1 and new policy SHA-256, retaining the old candidate and policy;
- run the fresh Mac quick gate on C1;
- if it passes, revalidate the completed Study 1 outputs using the committed verifier and complete the remaining full-suite stages under the new frozen policy;
- prefer safely reusing the 258 existing Study 1 trajectories rather than spending another 27 minutes regenerating them, under the exact provenance/dependency conditions in the binding decision;
- if safe verified resume is unavailable, a fresh full run after the new quick gate is authorized. Do not manufacture a completed-stage manifest or change original producing metadata to simulate resume;
- do not change any rule or source during the new quick/full execution.

A minimal verification-only resume/revalidation entry point is authorized only as specified in the binding decision. Preserve the original fresh-run behavior and reuse the existing scientific stage functions; do not duplicate the campaign algorithms.

## Return and stop

Return a compact package with:
- C0, C1, old/new policy identities and exact source diff;
- the limited cross-term claim-applicability table;
- test results, original failed evidence and revised-policy Study 1 revalidation;
- full mandatory coverage, including all eight previously unprocessed files;
- every raw sign difference and diagnostic qualification, kept distinct;
- actually executed/reused/missing stage counts and producing-versus-verifying provenance;
- quick/full results actually obtained;
- a Windows #2 instruction with the new frozen identifiers (do not execute on Windows yourself).

Retain large trajectories locally with hashes. Do not push/tag, clean the repository, edit LaTeX, declare P07 closed, or claim independent confirmation. Then STOP.
