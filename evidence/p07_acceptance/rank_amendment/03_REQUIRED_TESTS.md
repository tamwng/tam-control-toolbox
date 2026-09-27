# Required incremental tests (not substitutes for all-family verification)

Keep the original comparator/unit/CSV/source/outcome tests. Add these deterministic
synthetic/saved-fixture cases to test the amendment, without production trajectories.

1. Supplied historical index-765 fixture: formation/decomposition pass; nominal
   tau rank=1; envelope rank=[1,2]; n=3; robustly threshold-deficient=true;
   raw condition unresolved. The single-matrix verdict is ELIGIBLE/QUALIFIED-
   PREREQUISITE only, not exact rank or a whole-run PASS. Threshold-rank scalar
   is unresolved when rankResolved=false; point rank remains separately available.
2. Original index-1067 fixtures: preserve previous stable rank-1 qualification
   eligibility with all parent/source checks. Do not reinterpret prior outputs.
3. Interior threshold boundary: G=diag([1,tau,1e-20]), with consistent own
   normalized regressors. It has unresolved rank detail but definite deficiency.
   Pairing it with itself in an authorized P7 scope may qualify only after all
   pair/prerequisite checks pass. Same raw condition unresolved remains disclosed.
4. Full-rank boundary: G=diag([1,tau]) leaves rank 2 possible; it remains BLOCKING.
5. Perturb the second diagonal on opposite sides of tau, e.g. tau*(1-1e-5)
   and tau*(1+1e-5), with the same third small entry. Even if matrix tolerances
   and envelope deficiency pass, differing nominal point ranks BLOCK qualification.
   Do not override a conflicting original scientific rank/count/flag either.
6. Fail an original stored rank/count/validity flag or a publication check while
   preserving equal matrices: the combined verdict must FAIL/BLOCK, not qualify.
7. Reuse a valid boundary matrix outside the 19 P7 scopes or for covariance/QP
   Hessian quantities: no new qualification is allowed.
8. Preserve all negative tests: bad formation/source membership, prohibited
   nonfinite masks, zero matrices, failed decompositions, failed covariance/QP
   positivity, resolved condition outside its envelope, unsupported dimensions
   or units, missing required fields. No qualification hides those failures.
9. Mixed run: one eligible passive diagnostic plus one failed trajectory or solver
   check must yield FAILED/BLOCKED at parent and campaign levels. A fully accepted
   run with an eligible diagnostic retains a visible qualified label and count.
10. Passive Gram-condition reducers retain exact selection/definition and their
    raw original values. A reducer including an unresolved parent is itself
    qualified/unresolved, not claimed as a reproduced finite extremum.
11. Saved sweep covers all retained files/indices including pilot_A_000.mat. It
    records each eligible boundary. If independent blocking failures exist,
    diagnostic collection can continue safely but commit/quick/full cannot start.
12. New policy version/hash, all-three-machine identity, preserved old failed
    artifact, and protected-source integrity are enforced. No self-referential
    commit hash is inserted into tracked policy files.

Run all pre-existing and newly implemented policy-family tests, not just the
matrix subset. Report tests actually run, not intended tests or drafted code.
