# P07 — identity-based disposition of the freezingRMS contrast blocker

Read `01_AUDIT_AND_BINDING_DECISION.md` and `04_REQUIRED_TESTS.md` first.

I approve the bounded, source-defined treatment of structurally zero-freezing
contrasts specified in this handoff. Implement it together with the previously
approved algebraic-cross-term applicability amendment included under
`previous_cross_term_handoff/`. This approval does not globally waive P11.

Preserve the original C0 failures and all raw numeric/sign/interval records.
Change verification/policy files only. Do not change scientific producers,
parameters, seeds, reduction or bootstrap algorithms, reference data, numerical
agreement limits, Gram rules, or actual publication claims.

The new treatment applies only to the specified Study 1
`measured_initialization_paired_contrasts.csv` freezingRMS rows where BOTH models
have a structurally zero freezing error: first-step contact, or held input with
a verified affine-in-state map. It is not selected by a small observed value.
Check all parent errors against the existing 1e-11 contact/affine identity
criterion and retain every existing validity, source, pairing, and numerical
check. Preserve raw confidence intervals; do not report their zero classification
as reproduced statistical significance.

Implement all required positive/negative regressions. Recheck every applicable
row, including previously passing ones, and all 535 saved Study 1 files. Confirm
that noneligible performance-contrast and publication guards remain unchanged.
Do not create another policy-only proposal for the explicitly covered cases.
Collect independent remaining saved-data blockers together where safe, but stop
before a commit/run if any mandatory blocker remains.

If all implementation and saved-data gates pass:
1. Create a NEW frozen candidate commit and policy hash; report both.
2. Run the fresh Mac quick gate on these identifiers.
3. If quick passes, run the ENTIRE full Mac suite from the beginning in a new
   output directory, including Study 1, all later studies, P06, and paper checks.
   The user's latest instruction requires one clean final end-to-end run, not
   resumed/reused Study 1 output for the final verification verdict.
4. Keep the new commit and policy unchanged throughout execution. Stop and retain
   an actual subsequent failure; do not amend rules during that run.

Earlier saved results may be used for verifier tests only; preserve their
producing/verifying identities. Do not overwrite the original failed run or call
it a pass. State explicitly that both policy corrections were developed after
observing C0 failures. This is not independent P08 confirmation.

Return a compact package with the diff, tests, complete applicability/claim table,
saved-data recheck, source/data integrity, new identifiers, quick/full reports,
all qualifications, and raw-output index. State exactly what ran and what did not.
Do not package gigabytes of trajectories; retain them locally with manifests.

Windows #2 must ultimately use the same new candidate and policy. Preserve any
C0 outputs there; do not update a shared/OneDrive checkout while either machine
is running MATLAB. Do not start Windows runs from this Mac task.

No cleanup, LaTeX edits, push, release tag, submission, or P07 closure claim.
Return a brief summary and STOP.
