# Collective Dynamics and Intelligence Emergence in Multi-Body Parallel Key Geometric Flow (PKGF) on N-Dimensional Context-Warped Manifolds

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Python: 3.12+](https://img.shields.io/badge/Python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![Fortran: 95/2003](https://img.shields.io/badge/Fortran-95/2003-orange.svg)](https://gcc.gnu.org/fortran/)
[![DOI: TBD](https://img.shields.io/badge/DOI-TBD-red.svg)](https://github.com/aikenkyu001/PKGF_Intelligence_Emergence)

## 🌌 Project Overview

This repository contains the rigorous theoretical framework, numerical simulations, and empirical data for **Parallel Key Geometric Flow (PKGF)**. This project shifts the paradigm of "Artificial Intelligence" from local optimization algorithms to **spontaneous emergence of stable attractors within coupled dynamical systems** on high-dimensional manifolds.

By integrating differential geometry, higher gauge theory, and collective dynamics, we demonstrate how social hierarchies and role differentiation (intelligence) arise as a geometric solution to spatial constraints.

### 📜 Academic Papers
- **English**: [Full Academic Paper (Native Rigorous Edition)](Docs/PKGF_Academic_Paper_en.md)
- **Japanese**: [日本語学術論文 (厳密版)](Docs/PKGF_Academic_Paper_jp.md)

---

## 🧠 Key Features

### 1. Multi-agent PKGF System
Agents are modeled as point-charge semantic flows on a $C^\infty$ compact manifold $M$. Interaction is governed by the co-differential of a 2-form potential, integrating desire, ethics, and emotion fields into a unified velocity field.

### 2. Dimensional Resolution ($D \ge n$)
Formally proves that the ratio of manifold dimensionality $D$ to agent count $n$ determines social stability. High-dimensional manifolds facilitate exponential relaxation to "Peaceful Silence," while under-determined regimes ($D < n$) sustain "Persistent Struggle" as a source of complex intelligence.

### 3. Spontaneous Symmetry Breaking
Utilizes equivariant bifurcation theory to show that accumulating internal tension $\mathcal{A}$ triggers a supercritical pitchfork bifurcation, forcing symmetric groups to spontaneously differentiate into stable Leader/Follower (Elite/Mass) roles.

### 4. Holonomy-preserving K-update
The agent’s internal logic structure (Parallel Key $K$) is updated via an adjoint holonomy process. Using a 6th-order Pade approximation for matrix exponentials, the system preserves $\det(K)$ as a first integral with $10^{-16}$ precision.

---

## 📂 Repository Structure

```text
PKGF_Intelligence_Emergence/
├── Docs/           # Rigorous Academic Papers & Proof Outlines
├── Part1/          # Core: 2-Body Symmetry Breaking (Phase A-C)
├── Part2/          # Social: 15-Body Hierarchical Crystallization (Phase D-E)
├── Part3/          # Scaling: N-Body vs N-Dimension Resolution (Phase G)
├── Scripts/        # Post-processing & Stability Analysis (Euler vs RK4)
├── requirements.txt # Python dependencies
└── run_all.sh      # Master reproduction script
```

---

## 🛠️ Reproducibility

To guarantee scientific integrity, all experimental results can be reproduced using the provided master suite.

### Master Parameter Table
| Parameter | Symbol | Value | Description |
| :--- | :---: | :---: | :--- |
| Time step | $dt$ | 0.1 | Euler integration step |
| Coupling constant | $\lambda$ | 0.5 | Strength of social potential |
| Affinity variance| $\sigma^2$ | 1.0 | Social structure diversity |
| Tension threshold | $\mathcal{A}_c$ | 1.0 | Critical point for bifurcation |
| Random Seed | `seed` | 42 | Fixed for benchmarking |

### Stability Verification
The L2 error between the 1st-order Euler scheme and 4th-order RK4 is $\approx 6.5 \times 10^{-5}$ over 100 steps, confirming the robustness of the numerical stage. Run `python Scripts/stability_analysis.py` for local verification.

---

## 🚀 Installation & Execution

### Prerequisites
- Python 3.12+ (NumPy, SciPy, Matplotlib)
- Fortran 95/2003 (`gfortran`)

### One-Click Reproduction
```bash
# Clone the repository
git clone https://github.com/aikenkyu001/PKGF_Intelligence_Emergence.git
cd PKGF_Intelligence_Emergence

# Install dependencies
pip install -r requirements.txt

# Run all simulation phases and generate logs
chmod +x run_all.sh
./run_all.sh
```

---

## 📚 Citation

If you use this work in your research, please cite both the foundational theory and this specific implementation.

### BibTeX
```bibtex
@techreport{miyata2026pkgf_emergence,
  author = {Miyata, Fumio},
  title = {Collective Dynamics and Intelligence Emergence in Multi-Body Parallel Key Geometric Flow},
  institution = {PKGF Intelligence Emergence Project},
  year = {2026},
  type = {Technical Report},
  url = {https://github.com/aikenkyu001/PKGF_Intelligence_Emergence},
  doi = {TBD}
}

@techreport{miyata2026pkgf_foundational,
  author = {Miyata, Fumio},
  title = {Parallel Key Geometric Flow in 12D Manifolds},
  year = {2026},
  doi = {10.5281/zenodo.19217632}
}
```

---

## ⚖️ License
This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details. Academic use is highly encouraged with proper citation.

---
**Author**: Fumio Miyata (2026)  
**Contact**: ai.kenkyu.001@gmail.com
