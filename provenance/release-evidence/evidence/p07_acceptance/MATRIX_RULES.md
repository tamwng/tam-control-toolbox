# Proposed matrix, condition and rank screens (P4–P7)

All new constants here are **proposed verification requirements requiring approval**. They define a conservative engineering screen, not a certified LAPACK backward-error theorem, an estimator uncertainty bound or proof of exact algebraic rank. Existing scientific symmetry/positivity/rank/validity checks remain unchanged. This draft did not execute the new matrix screens against a campaign or select constants from observed mismatches.

For a required finite real n-by-n matrix M in its original coordinates, let `eps=2^-52`, `rho=100*n*eps`, `s1=norm(M,2)`, `eta=rho*max(s1,realmin)`. A zero matrix has a separately recorded zero-spectrum/rank result; its condition is unresolved, not replaced by a finite number. Empty/known-model matrices use the exact existing non-applicability rule.

1. Save M, singular values with/without vectors, eigenvalues with/without vectors, raw/recomputed cond, MATLAB default rank, and (where applicable) the separately named threshold rank. Retain all raw signs, nonfinite masks and discrepancies. Never replace historical values.
2. Proposed SVD screen: `norm(M-U*S*V',2)<=eta`, `norm(U'*U-I,2)<=rho`, `norm(V'*V-I,2)<=rho`, singular values finite/nonnegative/sorted. Proposed symmetric-eigensystem screen on the same symmetrization already used by the original eigenvalue producer: reconstruction and eigen-equation residual each <=eta and orthogonality <=rho. Record the actual residuals, not only booleans. No correction is written back into M or a scientific output.
3. Covariance retains existing finiteness, `norm(P-P','fro')<=100*eps*max(norm(P,'fro'),realmin)` and successful `chol(P)` in the original implementation. QP H retains its own positive-definite/weight/constraint checks. A Gram screen cannot excuse a covariance or Hessian failure.
4. P4/P5 parent-matrix elementwise agreement must pass. Proposed eigenvalue agreement uses `1e-10*max(1,norm(M_ref,2)) + 1e-7*abs(lambda_ref)` for the corresponding sorted value/extremum. Required eigendecomposition/symmetry checks are independent; agreement cannot waive them.

For a Gram G with exact row membership/count m, reconstruct normalized R from each own run's saved data and unchanged row/column scaling. This is algebra on saved values, not a control rerun. Let `u=2^-53`, `gamma=(m+1)*u/(1-(m+1)*u)`. Require m>0 and denominator>0. Proposed formation consistency screen:

`norm(G - (R'*R)/m,2) <= 2*gamma*norm((abs(R)'*abs(R))/m,2) + eta`.

The two gamma terms allow both stored and checker dot-product/division rounding; eta supplies the proposed norm/decomposition screening allowance. This is a finite-operation consistency check, not a cross-run regressor bound or global trajectory theorem. Each raw/scaled regressor must separately meet its applicable agreement requirement. Original window definitions, early-prefix handling, full-window counts and sample indices remain exact. Scalar R/G scaling is not changed to pass.

## Operational resolution classification, proposed

After all screens pass, define singular-value screening intervals `[max(0,s_i-eta),s_i+eta]`. These are engineering screening envelopes, not interval-certified mathematical bounds. For `s_n>eta`, define

`k_low=max(0,s_1-eta)/(s_n+eta)` and `k_high=(s_1+eta)/(s_n-eta)`.

Use outward endpoint rounding in implementation. A condition is **screen-resolved** only if endpoints are finite and `(k_high-k_low)/max(1,(k_low+k_high)/2) <= 1e-6`. This proposes a one-part-per-million resolution screen; passing it does not promise the tighter observed-agreement requirement will pass. Each stored/recomputed condition must fall inside its own envelope (allow only endpoint rounding), and P6's separate additive `1e-8 + 1e-7*abs(k_ref)` comparison must also pass. Otherwise required covariance/QP conditions are BLOCKED, never qualified away.

For the separately named threshold rank, `tau=1e-10`. Singular value i is robustly above the threshold only if `s_i-eta > tau*(s_1+eta)`, and robustly below only if `s_i+eta < tau*max(0,s_1-eta)`. V2 amendment: record pointThresholdRank separately, rankLower=count(above), rankUpper=n-count(below), and rankResolved=(rankLower==rankUpper). An unresolved thresholdRank scalar is NaN. A boundary leaving full rank possible still blocks. An intermediate boundary may qualify only under every binding condition in rank_amendment/01_AUDIT_DECISION.md; both matrices must have rankUpper<n, matching point ranks and overlapping intervals, with all original scientific rank/count/flag and publication checks passing. Existing scientific `gramRank`, `gramValid`, deficiency counts and Inf convention remain exact and unchanged; this supplementary calculation never overwrites them. Extending this supplementary convention to Study 1/P06 is a distinct proposed semantic choice within consolidated row P7.

## Exact proposed qualification scope

The scope is the **19 entries assigned P7 in full_field_coverage.csv**, not all fields named “condition”: raw recent-Gram condition histories and their existing recent-Gram min/max diagnostic reductions in Studies 1–5/P06, plus the copied Study 2 histories inside Study 6 constraint evidence and the quick representative. It does not include eigenvalues, covariance, Hessian, trajectories, paper A.14, failed solves, event/rank/feasibility counts, or any unlisted output. All raw masks/Inf signs remain exact; no finite/Inf substitution is permitted.

The trajectory code logs these Gram diagnostics after the controller decision; no `src` controller/estimator code consumes `gramCondition`. P06 uses the Study 1 trajectory; Study 6's constraint `runs` are exact copies of four Study 2 runs. Summaries and figures do read the diagnostics. Therefore the proposed qualification is conditional on retaining that passive call path and checking every parent matrix, regressor, rank and outcome. A future scientific dependency or unknown consumer blocks applicability.

If both raw finite conditions are unresolved by the screen, and every other required check passes, propose `QUALIFIED_WITH_UNRESOLVED_GRAM_DIAGNOSTIC`, with explicit exception count and raw discrepancy. This is **not numerical equality PASS**. Without author approval of P7 the verdict remains BLOCKED. Any failing formation/decomposition/parent/rank check blocks even an approved exception.

A passive min/max whose contributing set includes an unresolved raw condition is itself marked UNRESOLVED; preserve its raw value and source definition rather than claiming the numeric extremum reproduced. Preserve original selected indices/counts. In particular, Study 1 `run_diagnostics.gramConditionMax` is recomputed from full-window Gram matrices by the summary code; it is not necessarily `max(result.gramCondition)`. Retain those two provenance paths explicitly. This proposal changes only the claim/verdict, not report values, producing computations or historical files.

The identical 1067 fixture, prior Mac measurements and attached Linux reproduction support this treatment of near-singular diagnostics. Windows MATLAB evidence is still MISSING and no fresh cross-platform or full-suite result is inferred. All matrix-screen constants remain subject to the single consolidated review decision; they must be frozen before new validation results, not retuned afterwards.
