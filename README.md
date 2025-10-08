# Behavioral RLS-Predictive Control (BRLS-PC) MATLAB Pilot

This repository implements and tests the **Behavioral RLS-Predictive Control (BRLS-PC)** framework.  
It provides modular MATLAB code for both SISO and MIMO systems, designed for transparency, and reproducibility.

---

## 📁 Folder Structure
<pre>
bkrls/
└── core
    ├── window.m # Manages signal windowing (y_{k-ℓ:k-1}, u_{k-ℓ:k})
    ├── kernel.m # Kernel dictionary: ones, linear, polynomial, RBF, mixed
    ├── regressor.m # Builds ψ_k, g_k, z_k, φ_k, and returns metadata
    └── rls_update.m # RLS parameter update with forgetting, ridge, SPD checks
pc/
└── core
    ├── controller_step.m # computes next control (orchestration)
    ├── cost_assemble.m # forms H≻0,ℎ for BRLS-PC
    ├── solve_cholesky.m # Cholesky solve
    └── toeplitz.m # builds 𝑇𝑦, 𝑇𝑢, 𝑠𝑘 from Θ, 𝑠𝑘, 𝑁, ℓ
tests/
├── bkrls
|   └── core
|       ├── test_window.m # Unit tests for alignment/readiness logic
|       ├── test_kernel.m # Unit tests for kernel evaluation and dimension
|       ├── test_regressor.m # Unit tests for regressor construction
|       └── test_rls_update.m # Unit tests for RLS algebra, SPD, and determinism
└── pc
    └── core
        ├── test_controller.m
        ├── test_cost_assemble.m
        ├── test_solve_cholesky.m
        └── test_toeplitz.m
</pre>

## 🧩 Conceptual Overview

### Behavioral Kernel-Recursive Least Squares (BK-RLS)
BK-RLS identifies a **state-free input–output model** directly from data.  
It extends ARX structures with kernelized regressors while preserving linearity in parameters.

At each step:
<pre>
1. A window of past signals is formed:  
   \( s_k = (y_{k-\ell:k-1}, u_{k-\ell:k}) \)
2. A kernel dictionary \( g_k = [\gamma_1(s_k), …, \gamma_q(s_k)]^\top \) is evaluated.
3. The base signal vector \( \psi_k = [1; y_{k-1:\ell}; u_{k:\ell}] \) is built.
4. The Kronecker product \( z_k = g_k \otimes \psi_k \) forms the regressor.
5. Prediction: \( \hat{y}_k = \Theta z_k = \phi_k \theta \)
6. RLS update:
   \[
   \begin{aligned}
   L_k &= P_k / \lambda \\
   P_{k+1} &= L_k - L_k \phi_k^\top (I + \phi_k L_k \phi_k^\top)^{-1} \phi_k L_k \\
   \theta_{k+1} &= \theta_k + P_{k+1} \phi_k^\top (y_k - \phi_k \theta_k)
   \end{aligned}
   \]
</pre>

All operations are numerically guarded (SPD, finite checks, symmetry enforcement).

### Cost Assembly and Cholesky Solution (BRLS-PC)

This stage converts the identified behavioral model into an optimal control action.
Given frozen Toeplitz operators from LPV-ARX propagation, it assembles the quadratic cost and solves it analytically.

At each control step:

<pre> 1. Construct prediction operators: \( S_k = (I - T_y)^{-1}\sigma_k,\quad G_k = (I - T_y)^{-1}T_u \) 
2. Define tracking cost: \[ J(U) = \tfrac12\|S_k + G_kU - R\|_{Q_y}^2 + \tfrac12\|U\|_{R_u}^2 \] where \(Q_y \succeq 0\) and \(R_u \succ 0\). 
3. Expand into canonical quadratic form: \[ J(U) = \tfrac12U^\top H U + h^\top U + J_0 \] with \(H = G_k^\top Q_y G_k + R_u\), \(h = G_k^\top Q_y(S_k - R)\). 
4. Compute minimizer via Cholesky: \[ H = L L^\top,\quad L z = -h,\quad L^\top U^\star = z \] giving the closed-form solution \(U^\star = -H^{-1}h\). 
5. Apply only the first control block \(u_k = E_1 U^\star\) (receding horizon). Numerical guards ensure \(H\) is symmetric positive definite. If \(R_u\) is strictly positive definite, the solution exists uniquely without requiring any QP solver.
</pre>

## 🧪 Testing

### BKRLS

All core components are covered by **MATLAB Unit Tests** (`matlab.unittest`).  
Run the full suite from the project root:
```matlab
addpath(genpath('bkrls'));
runtests('tests');
```

Each test validates shape, algebraic consistency, and determinism.

| File | Purpose |
|----------|----------|
| **`test_window.m`** | Checks signal alignment and readiness flags |
| **`test_kernel.m`** | Verifies all kernel types and error handling |
| **`test_regressor.m`** | Confirms shape, Kronecker identity, and NaN handling |
| **`test_rls_update.m`** | Tests algebra, SPD properties, and batch equivalence |

### BRLS-PC

All predictive-control components are covered by **MATLAB Unit Tests** (`matlab.unittest`).
Run the verification suite from the project root:
```matlab
addpath(genpath('pc'));
runtests('tests');
```
Each test validates algebraic consistency, SPD guarantees, and closed-form equivalence with direct quadratic evaluation.

| File | Purpose |
|----------|----------|
| **`test_cost_assemble.m`** | Verifies correct formation of 𝑆𝑘, 𝐺𝑘, 𝐻, ℎ, 𝐽_0; checks symmetry, dimensions, gradient and Hessian identities, and SPD behavior |
| **`test_solve_cholesky.m`** | Confirms analytical solution 𝑈^⋆=−𝐻^−1ℎ; compares to MATLAB backslash; validates cost consistency, determinism, and non-SPD handling |

Both modules are numerically guarded (symmetrization, SPD checks, NaN propagation) and operate in pure double precision.

## ⚙️ Configuration

### BKRLS

Edit `cfg` structures in demos to adjust:
- `p, m, ell`: system dimensions and lag order
- `lambda`: forgetting factor (0.98–1.0 typical)
- `rho`: ridge regularization (10⁻⁴–10⁻⁶)
- `noise_std`: output noise
- `seed`: RNG reproducibility
- `T`: data length

### BRLS-PC

Edit `cfg` structures and weights in demos to adjust:
- `N`: prediction horizon (e.g., 10–40)
- `Q_y`: output-error weight (PSD). Typical: `kron(eye(N), diag(q_y))`
- `R_u`: input-effort weight (PD). Typical: `rho*eye(m*N), rho∈[1e-4,1e-2]`
- `R`: reference trajectory in 𝑅^𝑝𝑁 (stacked)
- `assert`: logical for guards (`true` default)
- `eps`: numeric tolerance (`1e-12` default)
- `J0`: optional constant for logging optimal cost (passed to `solve_cholesky`)
- `Ty, Tu, ofs`: Toeplitz operators and offset from propagation (sizes imply `p,m,N`)
- `ridge`: optional extra PD bump on `Ru` if `chol` fails (add `ridge*I`)
- `apply_first_block`: use only first m entries of 𝑈^⋆ each step (receding horizon)