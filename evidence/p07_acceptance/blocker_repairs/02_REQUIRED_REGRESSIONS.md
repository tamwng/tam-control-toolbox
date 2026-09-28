# Required regressions and saved-data revalidation

These tests implement the two decisions in document 01. Do not redesign the numerical policy. Tests can use saved fixtures and small synthetic corruptions; no new study trajectories are required.

## B1: outer MAT-variable namespace only

1. **Actual positive fixture:** preserve the original F2710 failure under the old order rule; the portable root accepts the same retained names in the two saved orders and then actually executes all descendants. Log raw orders, exact name set, scope, and rule version.
2. **Default/in-scope boundary:** the same comparator without the new scoped amendment retains its original behavior. Any other file/group/coverage path retains its previous order rule.
3. **Variable integrity:** missing `cfg` or `sources`, an extra retained variable, a renamed variable, wrong class, or wrong root shape fails. Merely sharing some names is insufficient.
4. **Nested ordering:** reordering fields inside cfg or inside any scientific source structure still fails. Reordering sources' cell elements or a scientific array still fails.
5. **Scientific leaves:** mutate a seed, threshold, horizon, fitting length, data selection, numeric class/shape, or scientific setting and verify the corresponding descendant check fails. Do not treat the root namespace pass as a file pass.
6. **Metadata does not waive provenance:** the existing source/execution exclusions remain exactly the same; wrong, missing, changed, or stale source links still fail their separate requirements. Test a wrong source hidden behind a syntactically admissible directory name.
7. **Complete real revalidation:** check the previously blocked actual settings descendants with the implemented MATLAB verifier and their source relationships. A Python fixture comparison or a prior 333-link success is not a substitute. Record exact executed scopes/counts without inventing an expected leaf count.
8. **Read-only guarantee:** retain both original MAT hashes; no sorting/resaving or reference replacement is allowed.

## B2: portable raw Gram maximum reporting binding

1. **Strict mode preserved:** the supplied first Mac/historical row still fails the old 32-eps assertion; historical own-source checks pass as before. Default report and plotter behavior is unchanged.
2. **Resolved numerical route:** test the first actual A row through the full parent/resolution path and unchanged P6 rule. A failed parent or numerical bound must fail even if other checks pass.
3. **Unresolved route:** test all three actual P3 rows and any other row meeting existing P7 conditions. P3 cannot be labelled ordinary P6 numerical agreement. Retain raw values, source identities, and qualification reasons. A large condition value alone must not activate P7.
4. **Both extrema witnesses:** use P3 amplitude 0.2 (indices 338/182) and amplitude 0.6 (537/180). Compare parents at like indices and preserve each side's own maximum calculation; do not invent cross-index matrix/rank equality or an exact cross-run argmax requirement.
5. **Own-source protection:** corrupt the historical CSV maximum within the looser P6 budget but outside its original own-source bound; it must fail. A corrupt current reduction, wrong history, changed source hash, stale cached evidence, or unsupported field/selector also fails.
6. **Selection and report requirements:** corrupted `gramCount`, full-window membership, `nSteps`, dimensions, parameter count, model/amplitude identity, threshold, rank range, deficient count, valid/invalid count, completion status, or source linkage must still fail its applicable original check.
7. **Nonfinite protection:** test NaN, wrong-sign infinity, invented infinity on an inadmissible parent, missing parents and unsupported sources. No generic matching-nonfinite acceptance is permitted. Preserve existing valid source-specific routes.
8. **No catch-and-skip:** inject a failure after the old stopping location and in a later adaptive row. Prove the portable path reaches and rejects it. Inject a plotted-data/source-table mismatch and prove the original figure assertion still rejects it. Callback absence/malformed status must not silently pass.
9. **All cases, not failed-row selection:** revalidate the entire actual 15-row adaptive report and all 18 total model rows, preserving three known-model N/A rows. Recompute the original rank/validity report with the same `study2_gram_diagnostic`; do not modify its algorithm or tolerance.
10. **Full saved figure/source path:** run the existing Study 2 plot/report path on saved Mac results in a NEW diagnostic output directory, with the portable callback. Verify both panels and all 33 source-table points using existing assertions. Check the rank-report export and exact raw source/reduction links; leave historical output paths untouched.
11. **Preserve calculations:** verify the optional-hook version gives the same returned report/plotting values as the original scientific/reporting computations for the same saved input. Qualification evidence must not change a raw maximum, corrected rank-based condition, or plotted score.
12. **Scoped guards:** demonstrate that QP Hessian/covariance checks, F0698, other extrema/timing selectors, and genuine scientific claims retain their rules. B2 introduces no exception outside the named passive-Gram plotting reduction.

## Integrated gate and stopping point

- Run the complete current verifier regression suite after both repairs; the old 279/279 result predates them.
- Recheck affected Study 6/paper source paths and the complete Study 2 reporting path from saved inputs. Refresh the consolidated coverage/blocker report. Independent unchanged successes may retain their original provenance; they are not newly executed tests.
- Record all requested checks that could not run; no missing/blocked requirement counts as a pass.
- Verify numerical constants, rank rules, original strict logic, protected references, and all unaffected scientific source bytes remain unchanged. Record the explicitly authorized reporting-hook diff and hashes instead of rewriting the prior manifest.
- Preserve old failure directories and create new evidence directories. Record generating versus verifying identities accurately.
- Return `READY_FOR_AUTHOR_REVIEW_NOT_CERTIFIED` only when all mandatory local checks succeed with only approved recorded qualifications; otherwise return a consolidated `BLOCKED` report.
- **No candidate commit, quick/full certification, Windows execution, cleanup, publishing, or LaTeX work. Wait for explicit user instruction.**
