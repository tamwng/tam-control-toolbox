# P07 B1/B2 — HQ readiness decision

## Decision

**Accept the B1/B2 repairs and the reported local diagnostic readiness.** No additional mandatory blocker was identified in the reviewed repair scope. No new numerical tolerance, rank rule, scientific change, or reference change is approved or requested.

This is **READY_FOR_AUTHOR_AUTHORIZED_FREEZE**, not cross-machine certification and not P07 closure. The work remains uncommitted and certification remains paused. This decision does not authorize a commit, quick/full run, Windows execution, cleanup, or LaTeX change.

## 1. Basis and independent checks

Reviewed `P07_B1_B2_REPAIR_REVIEW.zip`, SHA-256
`5c33d9581fe2656d05472f072afe124dee7dfe3e789924db3cc899885f1ed02e`.

Read `HQ_REVIEW_PROMPT.md`, `READINESS_REPORT.md`, the repair-only patch, the exact hook annex, required-check coverage, final test and saved-data ledgers, preservation records, and identifier records. Compared the three supplied authority documents byte-for-byte with the earlier HQ decision package.

Independent container checks:

- All **88 manifest-listed members** match their sizes and SHA-256; the manifest is the sole unlisted member.
- Applied the supplied patches to the exact earlier source copies for the comparator, plotter, Gram report, and effective policy. Reconstructed those files and the 15 additions; all **19 available reconstructed new hashes** match. The other two existing-file changes were reviewed as diffs; their full earlier bodies were not reconstructed here.
- Independently compared old and new effective-policy numeric leaves: **72 before / 72 after, all unchanged**.
- The final test CSV contains **303 unique tests**, all recorded passed, zero failed/incomplete. This verifies the supplied record, not a new MATLAB execution.
- The file-coverage CSV contains **2,877 unique files**: 2,876 carried-forward V6 passes and one newly passed V7 B1 settings comparison. The original settings failure is retained.
- The B1 full-field MAT ledger contains 268 recorded container/leaf verdicts, all passed; the summary reports 233 scientific leaves and 537 numerical values. The source-link CSV has 333 records. MATLAB string encodings in the MAT ledger are not independently decoded here; the full MATLAB traversal and source checks remain supplied execution evidence.
- Independently matched all **15 Study 2 raw maxima**, own selections, own first-max indices, binary64 encodings, original 32-eps failures, and P6 scalar inequalities to the complete histories in the earlier supplied fixture. Both run-source hashes were used to identify each pair.
- Independently checked all **17 same-index matrix witness pairs** against the previous fixture. Their maximum entry discrepancy is `7.771561172376096e-16`; nominal NumPy ranks at the existing relative threshold agree within each pair. This is not a replacement for all P7 formation/decomposition/parent guards.
- Checked paper-ledger count consistency: 21,016 export-field verdicts, 132 conditioning verdicts and 1,530 Table 12 verdicts, with zero failed fields in the supplied grouped records.
- Inspected the rendered Study 2 PDF: both panels, legend, and axes are readable. The plotted CSV has 33 rows, split 15/18 between panels, and the corrected rank report has 18 rows. Exact plot-to-source checks are recorded by MATLAB.

See `INDEPENDENT_CHECKS.json` for the numerical checks and their limits.

## 2. B1 — accepted

The implemented amendment is limited to portable F2710, `study6/settings.mat`, outer `value` namespace. It requires the exact retained name set `{cfg,sources}` and records both raw orders. It does not recursively sort scientific structures or rewrite a MAT file.

Recursive checks continue after the namespace check. Nested order and cell ordering remain mandatory. The added descendant class/shape guard enforces, rather than relaxes, the original exact representation requirement. Ordered own-source copies and canonical source-directory bindings remain checked.

The supplied execution reports all 233 scientific leaves / 537 values, 333 derived source relationships, and ten own-settings parent bindings passed. Negative tests cover missing/extra/renamed variables, other scopes, altered nesting, scientific values, numeric class/shape, source order, and wrong/stale/missing source records. The old portable root-order failure remains separately recorded. Nonportable default behavior remains unchanged.

**B1 is resolved for local saved-data readiness.**

## 3. B2 — accepted

The two exact reporting hooks preserve the strict default and change only the named raw `maxStoredCondition` verification site plus callback forwarding. The scientific Gram-report calculation, rank threshold, selected windows, and returned rank-based report/figure values are unchanged in the reviewed diff.

The portable binding validates own-source reductions before cross-run interpretation. The historical CSV remains pinned and must agree with its own MAT maximum under the old source contract. The callback validates all selected same-index parents and does not substitute a different reference, compare unequal times as corresponding parents, or waive later report/plot assertions.

Supplied results:

- 15 adaptive rows accepted and three known-model N/A rows retained (18 total).
- **Nine resolved numerical agreements; six qualified unresolved Gram reductions.**
- 11,250 selected parent checks, including 3,907 approved qualified parent instances.
- All 15 original strict maximum failures preserved.
- Original scientific validity, rank-report, figure-source, and later-assertion checks passed.

The six qualified maxima are **not numerical equality**. Three pass the scalar inequality alone but have unresolved parents; the three P3 maxima fail ordinary P6 agreement. The largest raw maximum discrepancy is `6.1321931160190336e21`. Its qualification remains explicit and conditional on its validated parents. The six new reporting qualifications are not the total number of qualifications across the full project; earlier trajectory qualifications retain their own provenance and must not be double-counted.

**B2 is resolved for local saved-data readiness.**

## 4. Source integrity — precise wording

The report records all 3,022 protected result/reference files (1,357,579,926 bytes) unchanged and all 12,982 indexed prior evidence files preserved. Those full local byte sets were not independently available to this audit.

The previous scientific-source inventory is **118/119 byte-identical**, not 119/119. The sole changed inventory member is the specifically approved `studies/study2/study2_gram_report.m` verification hook. The plotter forwarding change is separately recorded. Exact old/new hash pairs are authorized by the immutable annex; this is not a general source-change exemption. The old manifests remain preserved.

The source guard checks the pinned annex, authority, original source manifest and exact old/new hashes. Its tests include wrong hashes, unlisted paths, and missing/modified authority or annex records. No claim is made that unchanged scientific calculations imply all source bytes are unchanged.

## 5. Readiness is not certification

The repaired checkpoint combines **one new V7 file comparison with 2,876 earlier V6 comparisons**, together with newly run B1/B2 and paper checks. It does not establish that every file has been generated and checked by a fresh final V7 run.

The final paper revalidation is a new check of saved numerical exports, not a read of a newly compiled manuscript or a successful fresh end-to-end reproduction. Recorded old strict paper-summary failures remain preserved; the approved portable requirements are the applicable local acceptance gate.

Historical developing-policy failures must not be relabeled as passes. The final accepted policy must be identified as frozen before the later certification run, not as fixed before all the earlier failures that motivated its amendments.

## 6. Identifiers at this review

- Base HEAD (not the future repaired candidate): `de77ad73531abe100499abc1dc45099026f75667`
- Reviewed effective diagnostic policy SHA-256: `04925dc10f1b89c1a866c1d36bb58e033a79b070455230f6e4e80777d332e65d`
- Reviewed development snapshot SHA-256: `79e84b101920b5c99163f73e7aa5ed8fa7056c6ef75c9a771dd76c5225f54451`
- Repair-only patch SHA-256: `8cd92f5b07a579dc388c4dbf3fedc57f894c18c09c79c101f30cd1ece5b36852`
- Exact hook-annex SHA-256: `a3557128d5b402efdb80ffd83937dd49f32a7d1b949860109868ec00889bc682`
- Policy state: `active:false`; source changes uncommitted/unstaged.

These are reviewed development identifiers. Do not describe the base HEAD as containing the uncommitted repairs. Any subsequently authorized activation/freeze must record the actual complete candidate and effective-policy identifiers; do not retain a stale hash if policy bytes change.

## 7. Next stage — available after separate user authorization

No additional policy-design round is indicated by this package. The next stage is:

1. Freeze the reviewed verifier/policy and exact integrity annex into a new candidate, preserving prior evidence and scientific dependencies.
2. Run the fresh Mac quick gate, then the entire fresh full suite from the beginning under that candidate and effective policy. No acceptance-rule changes during execution.
3. Run Windows #2 under the same final candidate, policy and reference identities.
4. HQ audits the complete machine reports and records exact/numerical/qualified outcomes. Only then prepare the bounded LaTeX reproducibility insertion and reviewer response.
5. Keep the later pedagogical/journal-neutral cleanup separate, with its own diff, regression and final public-release identity.

Windows #1 remains the historical reference unless it is separately rerun. Do not claim the final candidate was executed on three computers without that evidence. P07 closure and P08 independent confirmation remain separate.

**Pause remains in effect. No commit or certification run is authorized by this readiness review.**
