# Structure-Informed Indirect Adaptive Predictive Control

This MATLAB software studies how supplied nonlinear functions and coefficient relations affect identification, prediction and constrained control. Recursive least squares (RLS) estimates coefficients in a fixed regressor. The fitted model reconstructs a nonlinear predictor; its value and Jacobian define an affine model held fixed over each control horizon.

The accompanying research is *A Numerical Investigation of Indirect Adaptive Predictive Control with Structure-Informed Nonlinear Regressors*. The numerical evidence is exploratory. It does not establish independent confirmation, general closed-loop stability, recursive feasibility or parameter convergence. A known-model controller uses the same frozen-affine control problem and is a diagnostic reference, not a performance bound.

## Requirements

Use MATLAB with licensed Optimization Toolbox (`quadprog`). The small public workflow was tested on Windows with MATLAB R2026a Update 5 and Optimization Toolbox 26.1. Other releases are unverified. Open MATLAB in the directory containing this README; keep the source layout intact. Public commands select this tree's functions and restore your previous directory and path when they return.

## First example

```matlab
[output, summary] = run_example;
```

This generates the fixed noise-free Shared-model example for Plant A: 200 fitting transitions, a separate 600-transition forecast-evaluation record, and 120 seconds of control at 0.1-second intervals. It uses the existing fixed seeds and settings. It needs no prior results or historical reference dataset. The example is trial 0; the paper's noisy representative trial 1 remains a different selection.

The new `results/example_*` directory contains:

- `data/confirmation_S_000.mat`: result, unchanged settings and generated fitting/evaluation records.
- `metrics.csv`: the existing whole-record and stationary-window scores, including tracking/input RMS and constraint diagnostics.
- `summary.json`: internal checks, metrics, environment and source/output identities.
- `function_resolution.csv`: the functions selected from this source tree.

The returned `summary` and console output report internal validity separately from reference comparison. A failed check raises an error and retains a failure record. Existing destinations are rejected; `run_example('my_example')` selects a new `results/my_example` directory.

## View and check the saved result

```matlab
resultFile = fullfile(output,'data','confirmation_S_000.mat');
[fig, selection] = inspect_results(1,'confirmation_S_000',output, ...
    'SaveTo',fullfile(output,'response.png'));
checks = check_result(resultFile);
```

The figure shows true output and reference, tracking error, applied input, coefficient estimates and forgetting factor. The controller is not rerun. The plot omits the unused terminal input; state endpoints and control intervals retain their original alignment. Full source provenance stays in `selection`, `fig.UserData` and the export's JSON sidecar. Omit `SaveTo` to display without writing an image.

Generation already checks the original timing, plant recurrence, fitted-state transfer, independent batch-RLS solutions, constraints, solver acceptance and forecast identities. `check_result` repeats these checks on the saved record. Internal validity does not establish agreement with a historical result.

For the small existing unit/regression selection:

```matlab
tests = run_component_tests;
```

This explicit selection covers the numerical core, short Study 1 fixtures and synthetic comparison negatives. It requires no historical results. It is not the complete archive-dependent test suite.

## Run an individual study

The study settings and model map below identify the original experiments. Use `help run_study1` through `help run_study6` for driver arguments. A complete Study 1 invocation in the retained reproduction environment is:

```matlab
studyOutput = run_study1('my_study1',Figures=false);
```

**Complete study drivers currently require the retained archive-dependent verification environment.** They are not the reference-free first example, and `Figures=false` only suppresses figures. Study 6 derives diagnostics from explicit saved Studies 1–5; it does not run additional control trajectories. [Reproduction and numerical verification](CROSS_PLATFORM_VERIFICATION.md#complete-study-and-paper-reproduction) lists the study-by-study and complete-paper routes, their prerequisites and limits. These longer routes were not executed for this public-interface checkpoint.

Changing a fixed setting defines a different experiment. No command above automatically starts a complete-paper or sensitivity campaign.

## Compare with the canonical reference

Set `referenceFile` to the separately supplied canonical `study1_candidate_20260917/data/confirmation_S_000.mat` record. Then reuse the generated MAT file:

```matlab
report = compare_reference(resultFile,referenceFile,'my_comparison');
```

This checks the reference identity and applies the unchanged released field-specific numerical policy to the saved representative. It does not fit or run the controller. `report.passed`, `report.status`, field outcomes and retained Gram qualifications identify what passed and under what conditions. A qualification is not numerical equality. The optional third argument saves compact comparison reports in a new output directory.

Missing references raise `reference:MissingReference`; a different reference raises `reference:Identity`. Neither is PASS. There is no automatic download or substitution. No public acquisition route for the canonical dataset is established. This command covers the fixed representative's full saved scientific record; it is not a compact-table comparison or complete-paper certification. See the [verification guide](CROSS_PLATFORM_VERIFICATION.md) for the exact scope and specification links.

## Directory, study and notation map

| Location | Purpose and paper correspondence | Key notation |
|---|---|---|
| `src/model_regression.m`, `src/RlsEstimator.m`, `src/regression_scaling.m` | Completed-transition regression and scaled RLS; Sections 3–4 | `theta`: raw coefficients; `beta=D.*theta`: scaled coefficients; RLS `P`: inverse-information state |
| `src/forward_map.m`, `src/freeze_predictor.m` | Nonlinear reconstruction and local affine approximation; Sections 3 and 5 | `A`, `B`, `c`: frozen Jacobians/offset; `C`: output selector |
| `src/assemble_qp.m`, `src/solve_mpc.m`, `src/AdaptiveController.m` | Constraints, solver acceptance and input timing; Section 5 | `N`: horizon; `Q`: output-error weight; `R`: input-increment weight |
| `studies/study1/` | Supplied structure and coefficient sharing, Plant A; Section 6.2.1 | A/S/W/R/P2/K are model IDs; model R differs from weight `R` |
| `studies/study2/` | Polynomial degree, restrictions and operating range, Plant B; Section 6.2.2 | Held-out prediction and constraint audit are separate |
| `studies/study3/` | Gain steps/drift and forgetting; Section 6.3.1 | No, fixed and variable-rate forgetting |
| `studies/study4/` | Fixed-dictionary structural change; Sections 6.3.2–6.3.3 | Retained-term activation versus out-of-class change |
| `studies/study5/` | Physical identification/reconstruction, Plant C; Section 6.4 | `theta=[J;d]`; output rad/s, input N m |
| `studies/study6/` | Diagnostics derived from saved Studies 1–5; Section 6.5 | Common-query nonlinear and affine forecasts |
| `studies/p06/` | Seven-setting sensitivity; Appendix A, Table A.18 | Input weight, prior and fitting length; [guide](studies/p06/README.md) |
| `tests/`, `studies/p06/tests/` | Unit/regression tests and fixtures | Some selections require historical data |
| `results/` | New output packages; created on demand | Generated and canonical records have distinct identities |

At time k, `u(k-1)` generated the completed measured transition, `u(k)` is committed, and the controller computes `u(k+1)`. Fitted coefficients and covariance both enter control. An admissibility map affects predictor parameters without replacing raw RLS estimates. Rejected control holds the committed input.

Plants A/B use dimensionless state/input coordinates; time is in seconds. Plant C uses physical units. Common-data tests share a fitting record and a separate evaluation record. Common-query forecasts share initial states and prescribed inputs while each model keeps its own selected snapshot fixed. Along-trajectory forecasts replay subsequently recorded inputs retrospectively. Prediction, tracking and parameter recovery are different outcomes.

Software attribution: [CITATION.cff](CITATION.cff). License: [BSD 3-Clause](LICENSE.txt).
