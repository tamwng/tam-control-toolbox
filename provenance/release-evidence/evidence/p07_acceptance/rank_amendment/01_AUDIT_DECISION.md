# P07 — narrow intermediate-rank-boundary amendment

## Decision

Approve a **verification-only policy amendment** and continuation of the already authorized implementation -> verifier tests -> candidate commit -> Mac quick -> Mac full sequence, subject to the gates below. Do not restart policy design.

The current attempt correctly stopped under the old rule. This approval does **not** convert that attempt to a pass and does not establish that the suite, a new commit, or Windows verification exists.

The previous blanket rule required a uniquely resolved supplemental numerical-rank count before an unresolved passive Gram condition could be qualified. For an **intermediate singular value**, that requirement is unnecessarily strong when the matrix is unambiguously deficient at the same threshold, the original scientific rank/count outputs still agree, and all other checks pass. This amendment changes that requirement, not any numerical tolerance or scientific result.

Sending `00_MAC_PROMPT.md` authorizes this amendment. This is a new, post-blocker policy decision; record it transparently rather than calling it the old frozen policy or a preregistered requirement.

## Reviewed inputs and independent findings

- Input: `P07_MAC_PORTABLE_VERIFICATION_REVIEW.zip`.
- SHA-256: `133d60852237bd8967267c5cb223c30becbc03c4efd0a4c506b12c11a7889e50`.
- Reported base HEAD: `75251c47d8c6ffd1806b84d7781ba35a0c2cba61`.
- Predecessor policy: `P07_PORTABLE_20260926_V1`.
- Predecessor policy SHA-256: `85ad97658ba7b234a911e802fd0628ebda982e3537161625fab5aea4229ff4ab`.
- All 53 entries in the supplied package manifest match their bytes and hashes.
- Supplied before/after protected inventories match at all 3,022 paths, sizes, and hashes, totaling 1,357,579,926 bytes. This checks the supplied indexes, not the live Mac archive.
- The supplied source patch contains only 14 new verification/documentation/test files. The live tracked-file integrity claim is supplied by Mac, not independently measured here.
- Mac reports six matrix tests passed and the saved sweep stopped after 495,722 matrix checks. This is not completion of all verifier rule families and is not a fresh reproduction run.
- The blocked fixture is `result.gram(:,:,765)` from `results/study1_candidate_20260917/data/pilot_A_000.mat`, source hash `7ea62f268778f2d93fcf88e1e4c4f36f9dca750b7972259eac4979bf5e884988`. It belongs to the retained inventory. Do not omit it because it is a historical pilot.

I independently loaded the saved binary64 matrix and its 50 normalized regressor rows. NumPy/SciPy formation and decomposition screens pass using the unchanged policy constants. The rank-screen interval is [1,2] for a 3-by-3 matrix. The lower/upper integers are screening results, not certified bounds on exact algebraic rank.

The reported Mac singular values are approximately:

- s1 = 1.8701316812233526;
- s2 = 1.8692121256784966e-10;
- s3 = 3.5360187113904707e-17.

The nominal cutoff is tau*s1 = 1.8701316812233526e-10 with tau=1e-10. The existing envelope eta = 1.2457579509450717e-13 overlaps this cutoff around s2. It does **not** overlap the full-rank boundary around s3: s3+eta is about 0.0006663 times the lower cutoff. Thus, under the existing screen, the unresolved detail is rank 1 versus 2, not deficient versus full rank 3.

The nominal point calculation at tau gives rank 1. MATLAB's reported **default** rank is 2 because it uses a different tolerance; these are distinct diagnostics. Neither number should silently overwrite the other.

An additional 80/120-decimal-digit mpmath calculation of the exact stored binary64 matrix places s2 about 9.193e-14 below tau*s1 and agrees at the displayed precision. This is a numerical cross-check, not a certified interval proof and not a new historical reference. No MATLAB, controller, estimator, new trajectory, or fresh Mac/Windows pair was executed here.

## Why this is not an observed rank disagreement between machines

The failure arose while screening one historical matrix on Mac. It is the **conservative supplementary envelope** that crosses the cutoff. The package does not demonstrate that a newly generated Mac matrix and a Windows matrix have different original numerical ranks, trajectories, or paper outcomes. Do not describe this stop as such a disagreement or assert that the whole suite is equivalent.

## Binding change to policy family P7 only

Policy-family P7 is the raw recent-Gram condition diagnostic rule. It is not manuscript task P07 as a whole.

Retain the same 19 schema scopes in `P7_QUALIFIED_SCOPE.csv`; its SHA-256 must remain `d8cceaa07496ecc87ab852f3095ffc9f7dc73dfab34791a26500e6d0524c077d`.

Retain all constants, including tau=1e-10, rho=100*n*eps, eta=rho*max(s1,realmin), formation and decomposition screens, array/spectral/condition agreement limits, masks, and exact original scientific checks. Do not make eta smaller to resolve this observed case and do not move tau.

For the supplementary screen, retain the existing predicates:

    above_i = (s_i - eta) > tau*(s1 + eta)
    below_i = (s_i + eta) < tau*max(0, s1 - eta)
    boundary_i = NOT (above_i OR below_i)

Report these separate quantities:

    pointThresholdRank = count(s_i > tau*s1)
    rankLower = count(above_i)
    rankUpper = n - count(below_i)
    rankResolved = (rankLower == rankUpper)
    robustlyThresholdDeficient = (rankUpper < n)

Where `rankResolved` is false, do not output `rankLower` as a resolved `thresholdRank`. Record an unresolved scalar (for example NaN plus explicit status) and the two bounds. Preserve the nominal point rank separately. These new fields belong to verifier reports, not protected scientific MAT/CSV outputs.

### Newly eligible branch

An intermediate rank-detail boundary may be **eligible for P7-qualified treatment**, rather than automatically blocking, only when ALL of the following hold:

1. The output belongs to one of the same 19 approved passive raw-Gram condition scopes. Its use remains diagnostic, with no effect on controller, estimator, solve acceptance, failure handling, or experimental selection.
2. The matrix is nonzero, finite, dimensionally valid, with valid source/row membership and unchanged coordinate/scaling definitions.
3. Its parent-matrix, regressor, formation, decomposition, symmetry where already required, and spectral checks pass under the existing rules.
4. The raw condition is unresolved under the existing condition-resolution screen. A resolved-but-outside-envelope condition is NOT eligible. Existing raw finite/nonfinite masks and signs remain exact; zero matrices and prohibited nonfinite cases still block.
5. `rankUpper < n` for each matrix: the screen resolves threshold deficiency even though an intermediate rank count may be unresolved. A boundary that leaves full rank possible is NOT eligible.
6. For a fresh/reference comparison, both matrices satisfy the above; their nominal `pointThresholdRank` values match and their rank intervals overlap. All existing original scientific rank values, validity flags, full-window counts, deficient-window counts, selections, and publication checks also pass exactly where already required. This amendment does NOT permit changed original ranks/counts to pass merely because both matrices are deficient.
7. No claim depending on a uniquely resolved supplemental rank count or on equality of the unresolved raw condition is marked verified. Such a required claim blocks until reviewed. The paper's existing reported rank ranges/counts are protected, not replaced with intervals.

The existing resolved-rank P7 path remains unchanged. The new path supplements it only for intermediate rank uncertainty with stable threshold deficiency and matching nominal/original outcomes.

### Status, propagation, and audit trail

- At the single-saved-matrix screening stage, use a distinct status such as `ELIGIBLE_P7_UNRESOLVED_INTERMEDIATE_RANK`, not a cross-platform PASS. A fresh counterpart may not exist yet.
- At the paired stage, after ALL prerequisites pass, use `QUALIFIED_WITH_UNRESOLVED_GRAM_RANK_DETAIL` or an equally explicit child status. Retain the unresolved raw-condition label as well.
- Count and index every qualified instance. Retain case/path/index, matrix dimension, point/default/original ranks where available, rank intervals, thresholds, screening margins, raw conditions/masks, original rank/count checks, and matrix/source check results.
- Passive condition min/max summaries containing such a value remain qualified/unresolved with their original reduction definition and source set. Do not present their raw extrema as reproduced or change their historical values.
- A qualified parent cannot hide a failed mandatory field. Propagate the qualification to the run and campaign report; do not label the result unqualified equality.
- An unresolved boundary with `rankUpper == n`, changed original rank/count/flag, unequal point ranks, failed matrix/condition/prerequisite, unsupported scope, or required publication mismatch remains blocking.
- Do not drop the pilot files, alter references, clip eigenvalues, replace singular values, change the primary rank convention, introduce higher-precision scientific producers, or increase tolerances.

This replaces only the old statement that *any* supplemental rank-boundary overlap automatically disqualifies P7. It does not waive any original scientific rank check. All other consolidated approval requirements remain in force.

## Implementation and execution

Use a new policy ID, e.g. `P07_PORTABLE_20260926_V2`. Preserve the old frozen JSON and hash in the previous evidence package. Update the current candidate policy/report documentation to identify this amendment; do not relabel V1 as passed. Record the new policy hash when its implementation is complete.

Implement within the existing verification allowlist. Test all rule families, including the new positive and negative boundary cases. The six existing matrix tests alone are not sufficient.

Complete the saved-data screening. A known eligible intermediate-boundary case under this amendment may continue without another per-matrix approval. Retain complete coverage; do not sample or exclude records. If additional blocking cases occur, finish the other independent read-only checks where safe and return ONE consolidated blocker report. No production execution or commit while mandatory gates remain failed or implementation incomplete. Do not stop collecting safe diagnostic information at the first matrix if that would obscure the remaining failure set.

If implementation tests, source/protected integrity, bindings, and saved-data gates all satisfy the policy (including only approved, disclosed qualifications), create the local candidate commit. Then run verifier tests and Mac quick from the frozen candidate; if accepted under the same rules, proceed to the full suite without another approval request. Preserve all old failures and output coverage.

Windows evidence remains missing. Both Windows machines must later use the same final candidate and policy; the old index-1067 matrix probe cannot certify this new case or the entire campaign. No Windows result is inferred here.

No LaTeX edits, repository pedagogical cleanup, push, tag, publication, P07 closure, or P08 confirmation is authorized by this amendment.

## Primary-source context (not endorsements of these policy constants)

- MathWorks `rank`: numerical rank counts singular values above a specified tolerance; default tolerance differs from a user-specified relative cutoff. https://www.mathworks.com/help/matlab/ref/rank.html
- MathWorks `cond`: the 2-norm condition is the largest/smallest singular-value ratio. https://www.mathworks.com/help/matlab/ref/cond.html
- LAPACK Users' Guide, SVD error bounds: backward stability controls errors on the scale of the largest singular value; relative accuracy of very small singular values need not follow. https://www.netlib.org/lapack/lug/node97.html

The [rankLower,rankUpper] screen here remains an author-approved engineering classification, not a certified interval analysis. Its use is restricted to the passive diagnostic verdict, while the original scientific calculations and reported outcomes remain protected.
