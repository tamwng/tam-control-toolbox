# Structure-Informed Indirect Adaptive Predictive Control

This MATLAB software studies how supplied nonlinear functions and coefficient relations affect identification, prediction and constrained control. Recursive least squares estimates coefficients in a fixed regressor. The fitted model reconstructs a nonlinear predictor; its value and Jacobian define an affine model held fixed over each control horizon.

The accompanying research is *A Numerical Investigation of Indirect Adaptive Predictive Control with Structure-Informed Nonlinear Regressors*. The evidence is exploratory: it does not establish general closed-loop stability, recursive feasibility, parameter convergence or independent confirmation. The known-model controller solves the same frozen-affine control problem; it is a diagnostic reference, not a performance bound.

## Requirements and first example

Use MATLAB with licensed Optimization Toolbox (`quadprog`). The representative workflow has been tested on Windows with MATLAB R2026a Update 5 and Optimization Toolbox 26.1; other releases are unverified. Start MATLAB in this directory and keep the source layout intact. Public commands select this tree's functions and restore the caller's path and directory.

```matlab
[output, summary] = run_example;
```

This fixed noise-free Shared-model example uses 200 fitting transitions, a separate 600-transition evaluation record and 120 seconds of control at 0.1-second intervals. It generates its own inputs with the fixed seeds and needs no historical results. Trial 0 is distinct from the paper's noisy trial 1.

The new `results/example_*` folder contains `data/confirmation_S_000.mat` (result, settings and records), `metrics.csv`, `summary.json` (checks, identities and environment), and `function_resolution.csv`. Existing destinations are rejected. `run_example('my_example')` selects a new named folder. Failures retain an error record.

## Inspect and check saved results

```matlab
inspect_results(1,'confirmation_S_000',output);
checks = check_result(fullfile(output,'data','confirmation_S_000.mat'));
run_component_tests;
```

The viewer does not rerun the controller. It shows state/reference and input histories, with provenance in figure metadata. Supply `'SaveTo','response.png'` to export. Internal checks cover applicable mathematical, finite-value, solver, constraint and implementation requirements; passing them is not agreement with published results.

## Individual studies and complete reproduction

```matlab
study2 = generate_results('study2',OutputDirectory='study2_run');
check_study_results('study2',study2);
```

This runs the **complete** selected study, not another inexpensive example. `Figures=false` is the generation default and changes plotting only. Study settings and case definitions are fixed. Generated manifests record own validity separately from reference comparison.

| Study | Purpose | Implementation |
|---|---|---|
| 1 | Structure-informed regressors and paired measurement-noise trials | `studies/study1/` |
| 2 | Input range, polynomial dictionaries and constraints | `studies/study2/` |
| 3 | Parameter changes and forgetting | `studies/study3/` |
| 4 | Fixed dictionaries under structural change | `studies/study4/` |
| 5 | Physical identification and predictor reconstruction | `studies/study5/` |
| 6 | Saved-data prediction and control diagnostics | `studies/study6/` |
| Sensitivity | Paired control-weight, prior and record-length cases | `studies/p06/` |

`src/` holds the models, RLS estimator and controller. In the implementation, `x`, `y` and `u` denote state, measured output and input; `theta` is a physical/model coefficient vector, `beta` its scaled estimate, `P` the estimator covariance, `Ts` the sample interval, and `N` the control horizon. Arrays retain the timing and units documented in function help.

Study 6 requires all five explicitly identified newly generated parents:

```matlab
parents = struct('study1',s1,'study2',s2,'study3',s3,'study4',s4,'study5',s5);
s6 = generate_results('study6',Sources=parents,OutputDirectory='study6_run');
```

Here `s1`–`s5` are returned complete-study directories from the same source identity. No historical fallback is used. To inspect sensitivity case IDs without simulation, use `run_sensitivity('plan')`. Run a named case with `run_sensitivity('case',Case='baseline_S_000')`.

```matlab
% Expensive: all original studies and the complete 1,558-case sensitivity set.
paper = generate_results('all',OutputDirectory='paper_run',ConfirmFull=true);
```

Complete generation, saved plotting and reference comparison are separate operations. Use `plot_results('study1',s1)` for saved publication figures. Study 2 publication plotting additionally requires `ReferenceInputs.study2` and `ReferenceInputs.rankFile`; absent rank evidence blocks that export. The ordinary time-domain viewer needs no reference.

## Independent reference comparison

For the fixed example, the full repository includes the canonical `results/study1_candidate_20260917/data/confirmation_S_000.mat`. Supply it explicitly:

```matlab
canonicalFile = fullfile(pwd,'results','study1_candidate_20260917','data','confirmation_S_000.mat');
comparison = compare_reference(fullfile(output,'data','confirmation_S_000.mat'), ...
    canonicalFile,'example_comparison');
```

The fixed-example reference is intact in the Git tree. Complete-study reference tables require byte-preserving distribution: ordinary Git exports do not preserve every frozen table identity. Until that route is available, obtain the exact dataset from its custodian; see the [reference requirements](CROSS_PLATFORM_VERIFICATION.md). Public download access is not yet verified. Missing or incorrect references raise an error and never produce PASS.

The complete-study interface is `compare_study_reference(sources,references,output)`, where both structures identify study directories. Supply current `ParentSources` and `ReferenceParents` where required. Study 6 requires both five-study parent sets; sensitivity also requires canonical Study 1. The resolver checks the frozen canonical file identities. See [verification requirements](CROSS_PLATFORM_VERIFICATION.md) for the exact local reference roots and dependency requirements.

Complete-study reference comparison checks the reviewed source relationship and the supplied datasets. The cleanup was checked with component tests, retained-data bindings, and a fresh representative example; the complete studies were not rerun during cleanup.

## Interpretation and provenance

**PASS** applies only to the explicitly reported checks and supplied inputs. **FAIL** means a required executed check failed; unavailable material means the comparison was not established. **QUALIFIED** identifies an approved limited diagnostic interpretation, including passive Gram diagnostics; it does not assert numerical equality. A run compared with itself is not historical-reference verification. A fixed example is not full-paper certification.

The [provenance note](provenance/README.md) distinguishes historical generating revisions from this development source. Historical certificates are not rewritten or inherited. Attribution and software citation remain in `CITATION.cff`; license terms remain in [LICENSE.txt](LICENSE.txt). No version 2.0.0 tag, public data-hosting claim or unissued paper citation is implied.

## Citation

The revised manuscript will be available on arXiv. The final citation and DOI
will be added when the updated public version is available.
