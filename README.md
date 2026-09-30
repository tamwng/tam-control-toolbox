# Structure-Informed Indirect Adaptive Predictive Control

This MATLAB package studies how nonlinear regressors and coefficient relations affect identification, prediction and constrained control. Recursive least squares fits a model whose value and Jacobian define an affine predictor held fixed over each control horizon.

The accompanying research, *A Numerical Investigation of Indirect Adaptive Predictive Control with Structure-Informed Nonlinear Regressors*, provides exploratory numerical evidence. It does not establish general closed-loop stability, recursive feasibility, parameter convergence or independent confirmation. The known-model controller is a diagnostic reference, not a performance bound.

## First example

Use MATLAB with licensed Optimization Toolbox (`quadprog`). The representative workflow was tested on Windows with MATLAB R2026a Update 5 and Optimization Toolbox 26.1; other releases are unverified. Start MATLAB in the repository root. Keep the source layout intact; public commands select this tree's functions and restore your original path and directory.

```matlab
[output, summary] = run_example;
```

This fixed noise-free example fits the Shared model using 200 transitions, evaluates 600 separate transitions, and runs 120 seconds of control at 0.1-second intervals. Inputs use fixed seeds. No historical results are needed. Trial 0 is distinct from the paper's noisy trial 1.

The new `results/example_*` directory contains the saved result, settings and inputs in `data/confirmation_S_000.mat`, metrics in `metrics.csv`, and checks, source identities and environment in `summary.json` and `function_resolution.csv`. Use `run_example('my_example')` for a named directory. Existing destinations are rejected; failures retain an error record.

Plot the saved response without rerunning:

```matlab
inspect_results(1,'confirmation_S_000',output);
```

Add `'SaveTo',fullfile(output,'response.png')` to export the figure. Its metadata identifies the source record.

## Individual studies and complete reproduction

```matlab
s2 = generate_results('study2',OutputDirectory='study2_run');
check_study_results('study2',s2);
```

This executes the **complete selected study**. It is more expensive than the example. Generation uses fixed study definitions and defaults to `Figures=false`; plotting is separate.

Study 6 requires complete newly generated Studies 1–5 from the same source identity:

```matlab
parents = struct('study1',s1,'study2',s2,'study3',s3,'study4',s4,'study5',s5);
s6 = generate_results('study6',Sources=parents,OutputDirectory='study6_run');
```

Here `s1`–`s5` are the directories returned by those study runs. For sensitivity, `run_sensitivity('plan')` lists the fixed cases without simulation; `run_sensitivity('case',Case='baseline_S_000')` runs one named case. See the [sensitivity guide](studies/p06/README.md) for the paired design.

```matlab
% Expensive: all six studies and the complete 1,558-case sensitivity set.
paper = generate_results('all',OutputDirectory='paper_run',ConfirmFull=true);
```

Use `plot_results('study1',s1)` for saved study figures. Study 2's publication figures additionally require the canonical rank file and its source dataset, described in the [verification guide](CROSS_PLATFORM_VERIFICATION.md). The ordinary time-domain viewer needs no reference data. Inspect selected sensitivity cases rather than plotting the entire campaign.

## Internal validity

Generation checks the applicable mathematical identities, finite values, solver conditions, constraints and implementation requirements. Recheck the saved example or run the small component suite with:

```matlab
resultFile = fullfile(output,'data','confirmation_S_000.mat');
checks = check_result(resultFile);
run_component_tests;
```

These checks assess the calculation itself. Passing them does not establish agreement with a reference dataset.

## Reference comparison

Canonical datasets are included under `results/`. For the example, supply the reference explicitly:

```matlab
canonicalFile = fullfile(pwd,'results','study1_candidate_20260917','data','confirmation_S_000.mat');
comparison = compare_reference(resultFile,canonicalFile,'example_comparison');
```

This reuses the saved result. Missing or altered reference material raises an error, never PASS. Preserve the reference paths and exact bytes.

For completed studies, use `compare_study_reference(sources,references,output)`. Study 6 also needs both five-study parent sets; sensitivity needs canonical Study 1 records. The [verification guide](CROSS_PLATFORM_VERIFICATION.md) lists the exact inputs, fixed numerical rules and plotting dependencies.

**PASS** applies to the reported checks and inputs. **FAIL** identifies a failed requirement; unavailable inputs leave comparison unestablished. **QUALIFIED** retains a specified limitation, including unresolved passive Gram diagnostics, and does not mean numerical equality. Self-comparison is not independent reference verification.

## Package map and provenance

| Location | Contents |
|---|---|
| `src/` | Models, recursive least squares and constrained controller |
| `studies/study1/`, `studies/study2/` | Regressor structure, measurement noise, input range and constraints |
| `studies/study3/`, `studies/study4/` | Parameter changes, forgetting and structural change |
| `studies/study5/`, `studies/study6/` | Physical reconstruction and saved-data diagnostics |
| `studies/p06/` | Paired tuning and initialization sensitivity |
| `tests/`, `results/` | Component tests; generated outputs and canonical datasets |

In the source, `x`, `y`, `u` denote state, measurement and input; `theta` and `beta` are model and scaled coefficients, `P` is estimator covariance, `Ts` the sample interval, and `N` the horizon. Function help specifies array timing and units.

The [provenance note](provenance/README.md) identifies the revisions used for historical cross-platform certification. Those records do not certify another source revision or a user's example. Software attribution is in `CITATION.cff`; terms are in [LICENSE.txt](LICENSE.txt).

## Paper citation

The citation and DOI for the revised arXiv version will be added when that version is announced.
