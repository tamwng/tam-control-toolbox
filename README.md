# Behavioral Kernel RLS (BK-RLS) MATLAB Pilot

This repository implements and tests the **Behavioral-Kernel Recursive Least Squares (BK-RLS)** identification framework.  
It provides modular MATLAB code for both SISO and MIMO systems, designed for transparency, reproducibility, and future extension to predictive control (BRLS-PC).

---

## 📁 Folder Structure
<pre>
bkrls/
├── window.m # Manages signal windowing (y_{k-ℓ:k-1}, u_{k-ℓ:k})
├── kernel.m # Kernel dictionary: ones, linear, polynomial, RBF, mixed
├── regressor.m # Builds ψ_k, g_k, z_k, φ_k, and returns metadata
└── rls_update.m # RLS parameter update with forgetting, ridge, SPD checks
tests/
├── test_window.m # Unit tests for alignment/readiness logic
├── test_kernel.m # Unit tests for kernel evaluation and dimension
├── test_regressor.m # Unit tests for regressor construction
└── test_rls_update.m # Unit tests for RLS algebra, SPD, and determinism
demos/
├── demo_siso_arx.m # SISO ARX identification with known ground truth
└── demo_mimo_arx.m # MIMO ARX identification (3×2 example)
</pre>

## 🧩 Conceptual Overview

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

## 🧪 Testing

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

## ⚙️ Configuration

Edit `cfg` structures in demos to adjust:
- `p, m, ell`: system dimensions and lag order
- `lambda`: forgetting factor (0.98–1.0 typical)
- `rho`: ridge regularization (10⁻⁴–10⁻⁶)
- `noise_std`: output noise
- `seed`: RNG reproducibility
- `T`: data length