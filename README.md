# Kernel--RLS Indirect Adaptive Predictive Control MATLAB Repository

This repository contains MATLAB code for finite-feature kernel--recursive-least-squares (kernel--RLS) input--output prediction embedded in an indirect adaptive predictive-control loop. The implementation is designed for numerical reproducibility, transparent inspection, and reuse in follow-up studies.

The codebase implements the main components used in the accompanying numerical studies:

- finite-history input--output windowing,
- finite feature dictionaries, including constant, linear, polynomial, radial-basis-function (RBF), and mixed dictionaries,
- block-structured kernel--RLS regression,
- LPV--ARX coefficient extraction from the identified predictor,
- finite-horizon frozen-predictor propagation,
- unconstrained quadratic predictive-control cost assembly,
- direct Cholesky solution of the resulting positive-definite normal equations,
- deterministic numerical examples and unit tests.

The repository is intended as a research artifact for reproducing the reported simulations. It does not provide general closed-loop stability, robustness, recursive-feasibility, or nonlinear approximation guarantees.

## 🚀 Quick Start

The examples used in the accompanying ArXiv paper are located in:

```text
brlspc/demos/arxiv/
```

To run Example 1:

```matlab
addpath(genpath('bkrls'));
addpath(genpath('pc'));

cd brlspc/demos/arxiv/ex1

run_ex1_kernel
```

Other examples can be executed in the same way from their corresponding
subdirectories.

## Associated paper

The public arXiv version associated with this implementation is:

> Tam W. Nguyen, "Adaptive Behavioral Predictive Control: State-Free Regulation Without Hankel Weights," arXiv:2602.12016, 2026.

The arXiv manuscript contains the full seven-example numerical study. The code in this repository provides the implementation and reproducibility infrastructure for those examples and related revised manuscripts.

The paper is available in `paper/arXiv_2602.12016.pdf`.

## Repository structure

```text
bkrls/
└── core/
    ├── window.m          # Signal windowing: y_{k-ell:k-1}, u_{k-ell:k}
    ├── kernel.m          # Feature dictionaries: constant, linear, polynomial, RBF, mixed
    ├── regressor.m       # Builds psi_k, g_k, z_k, phi_k, and metadata
    └── rls_update.m      # RLS update with forgetting, ridge regularization, and checks

brlspc/
└── demos/                # Numerical examples used in the manuscript/preprint

pc/
└── core/
    ├── controller_step.m # Receding-horizon control step
    ├── cost_assemble.m   # Forms H, h, and J0 for the predictive-control problem
    ├── solve_cholesky.m  # Cholesky-based solution of the normal equations
    └── toeplitz.m        # Builds T_y, T_u, sigma_k from the frozen LPV--ARX predictor

tests/                    # Unit tests
├── bkrls/
│   └── core/
│       ├── test_window.m
│       ├── test_kernel.m
│       ├── test_regressor.m
│       └── test_rls_update.m
└── pc/
    └── core/
        ├── test_controller.m
        ├── test_cost_assemble.m
        ├── test_solve_cholesky.m
        └── test_toeplitz.m
```

## Method summary

### Finite-feature kernel--RLS identification

At each time step, a finite input--output history is assembled as

```math
s_k = (y_{k-\ell:k-1}, u_{k-\ell:k}).
```

A user-selected finite dictionary is evaluated on this history:

```math
g_k = [\gamma_1(s_k), \ldots, \gamma_q(s_k)]^\top.
```

The base signal vector is

```math
\psi_k = [1;\, y_{k-1};\, \ldots;\, y_{k-\ell};\, u_k;\, \ldots;\, u_{k-\ell}],
```

and the block-structured regressor is formed using the Kronecker product or its intercept-aware variant. The one-step predictor is linear in parameters:

```math
\hat y_k = \Theta z_k = \phi_k \theta.
```

The parameter vector is updated by covariance-form RLS:

```math
\begin{aligned}
L_k &= P_k/\lambda, \\
P_{k+1} &= L_k - L_k\phi_k^\top(I+\phi_kL_k\phi_k^\top)^{-1}\phi_kL_k, \\
\theta_{k+1} &= \theta_k + P_{k+1}\phi_k^\top(y_k-\phi_k\theta_k).
\end{aligned}
```

### Frozen-predictor predictive control

After the RLS update, the identified predictor is compiled into an LPV--ARX form and frozen over the prediction horizon. This gives the stacked affine predictor

```math
Y = S_k + G_k U.
```

The unconstrained finite-horizon cost is

```math
J(U)
= \frac{1}{2}(S_k+G_kU-R)^\top Q_y(S_k+G_kU-R)
+ \frac{1}{2}\Delta U^\top R_u\Delta U,
```

where

```math
\Delta U = D U - d_k.
```

Expanding gives

```math
J(U) = \frac{1}{2}U^\top H U + h^\top U + J_0,
```

with

```math
H = G_k^\top Q_yG_k + D^\top R_uD,
```

```math
h = G_k^\top Q_y(S_k-R) - D^\top R_ud_k.
```

When `H` is positive definite, the control sequence is computed by Cholesky factorization:

```math
H = LL^\top, \qquad Lz=-h, \qquad L^\top U^\star=z.
```

Only the first block of `U^star` is applied, yielding a receding-horizon implementation.

## Installation and requirements

The code is written for MATLAB and uses only standard MATLAB functionality and the MATLAB unit-testing framework.

From the project root, add the repository to the MATLAB path:

```matlab
addpath(genpath(pwd));
```

## Running tests

Run the full test suite from the repository root:

```matlab
addpath(genpath(pwd));
results = runtests('tests');
table(results)
```

The tests check dimensions, algebraic consistency, symmetry, positive-definiteness conditions, deterministic behavior, and agreement with direct linear-algebra solutions where applicable.

## Running numerical examples

The numerical examples are located in:

```text
brlspc/demos/
```

A typical workflow is:

```matlab
addpath(genpath(pwd));
cd brlspc/demos
```

Then run the relevant demo script for the desired example. The examples use fixed random seeds and configuration files where applicable to support reproducibility.

## Configuration parameters

Common identification parameters include:

- `p`, `m`: output and input dimensions,
- `ell`: history length,
- `lambda`: RLS forgetting factor,
- `rho`: ridge regularization parameter,
- `seed`: random-number seed,
- `T`: simulation length.

Common predictive-control parameters include:

- `N`: prediction horizon,
- `Q_y`: output tracking weight,
- `R_u`: input-increment weight,
- `R`: stacked reference trajectory,
- numerical tolerances for symmetry and positive-definiteness checks.

## Citation

If you use this repository, please cite the associated arXiv manuscript:

```bibtex
@misc{nguyen2026adaptivebehavioral,
  title         = {Adaptive Behavioral Predictive Control: State-Free Regulation Without Hankel Weights},
  author        = {Nguyen, Tam W.},
  year          = {2026},
  eprint        = {2602.12016},
  archivePrefix = {arXiv},
  primaryClass  = {eess.SY},
  doi           = {10.48550/arXiv.2602.12016},
  url           = {https://arxiv.org/abs/2602.12016}
}
```

A `CITATION.cff` file is also provided for GitHub citation metadata.

## License

This repository is released under the BSD 3-Clause License. See [`LICENSE.txt`](LICENSE.txt) for details.

## Disclaimer

This code is provided for academic research and reproducibility. It is supplied without warranty of any kind. Users are responsible for verifying suitability, numerical behavior, and safety before applying the methods to any physical system.
