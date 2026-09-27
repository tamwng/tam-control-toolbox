# Required focused tests and completion checks

Retain the current approved positive/negative test coverage. Add or update:

## Exact zero branch
1. Nonempty exact zero G with exact zero own-parent R, m>=1, original rank=0 and +Inf masks: admitted structural case, no Inf-Inf numeric comparison, rank interval [0,0].
2. Zero G with nonzero R (including values small enough to underflow on multiplication): rejected for this branch.
3. Missing/empty/nonfinite/mismatched parent or row count: rejected.
4. Zero versus nonzero pair: not admitted by the structural-zero rule.
5. +Inf versus NaN or -Inf mismatch: rejected under original masks/signs.
6. Zero covariance or Hessian: still invalid; no Gram exception.

## Supplemental full-rank boundary
7. The seven P06 and three Study 4 saved boundary fixtures are eligible at the single-matrix stage only when all local prerequisites pass. Do not call them fresh/reference passes.
8. Synthetic/saved derived pairs with matching point ranks, overlapping intervals, passing parent/field checks and all original outcomes: visibly qualified.
9. Matrices within the entrywise tolerance but with different nominal point ranks: blocked.
10. Original rank/count/validity or publication outcome changed: blocked even with overlapping intervals.
11. Unsupported scope, active control use, failed matrix screen, resolved-but-outside-envelope condition, or disallowed mask change: blocked. For the new full-rank-boundary branch, require a finite envelope and reject an outside-envelope estimate even when its width is unresolved.
12. Wider-than-[n-1,n] full-rank-possible interval: blocked; old robustly deficient intermediate branch remains available only under its own prerequisites.
13. Both conditions resolved: normal numerical-agreement rule, not the qualified branch.
14. Failed required covariance/Hessian cannot be hidden by a qualified Gram child.
15. Qualifications propagate to summaries/run/campaign; unresolved raw max is never labeled numerically reproduced.

## Strict reporting adapter
16. Supplied approximately 1e-14 differences pass the already approved P6 target only when parent/reduction prerequisites pass.
17. Beyond-budget discrepancy fails; no blanket struct tolerance.
18. Changed exact IDs/counts/masks/sources or invalid covariance parent fails.
19. Preserve historical strict-failure status and run the new portable test, not a skipped/renamed failed test.

## Integration and lifecycle
20. Complete all remaining CSV source/unit/rule bindings; unknown fields fail closed.
21. Complete integrity, no-scientific-change diff, quick/full gate ordering, overwrite protection and qualification-propagation tests.
22. Report fresh distinct test counts without summing overlapping logs.
23. Create candidate only after all mandatory gates are accepted; quick precedes full and failure stops progression. Every run records candidate/policy identity.

No new production dependencies, scientific reference replacements, numerical tolerance changes, or per-file exception lists are authorized.
