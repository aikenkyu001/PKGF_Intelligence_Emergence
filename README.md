# Collective Dynamics and Intelligence Emergence in Multi-Body Parallel Key Geometric Flow (PKGF) on Multi-Dimensional Context-Warped Manifolds

This repository contains the comprehensive research data, theoretical documentation, and numerical simulations for **Parallel Key Geometric Flow (PKGF)**. The project explores the spontaneous emergence of intelligence and social hierarchy through the lens of differential geometry and collective dynamics.

---

## 🌌 Project Overview: The Geometry of Intelligence

PKGF is a mathematical framework describing information transition as a geometric flow (connection, metric, and curvature) on a manifold. This research extends PKGF to multi-body coupled systems to observe how "intelligence" emerges not as an algorithm, but as a stable attractor acquisition process under geometric constraints.

### Key Research Themes
- **Adjoint Holonomy Update**: Logic preservation ($\det(K) = \text{const}$) via parallel transport.
- **Co-differential Propulsion**: Motion driven by the divergence of a 2-form potential ($\delta F$).
- **Symmetry Breaking**: Spontaneous differentiation into roles (Leader/Follower) triggered by internal tension.
- **Dimensional Resolution**: Geometric resolution of social conflict in higher-dimensional manifolds ($D \ge N$).

---

## 📂 Project Structure

```text
PKGF_Intelligence_Emergence/
├── Docs/               # Academic papers, theorems, and mathematical definitions
│   ├── PKGF_Academic_Paper_jp.md  # Full Japanese paper (Rigorous Edition)
│   └── PKGF_Academic_Paper_en.md  # Full English paper (Rigorous Edition)
├── Part1/              # Phase A-C: 2-body symmetry breaking simulations
├── Part2/              # Phase D-E: 15-body social hierarchy simulations
├── Part3/              # Phase G: N-body dimensional comparison simulations
├── Scripts/            # Stability and analysis scripts (Euler vs RK4)
├── requirements.txt    # Python dependencies (NumPy, SciPy, Matplotlib)
├── run_all.sh          # Master reproduction script
└── PDF/                # Scientific references
```

---

## 🧠 Mathematical Foundations

### 1. Fundamental Equations
- **Co-differential Propulsion**:
  Velocity field $v$ is propelled by the co-differential ($\delta F$) of a 2-form $F = d\omega$ on a $C^\infty$ compact manifold $M$:
  \[ v^\flat = -(K^{-1} g^{-1}) \delta F = -(K^{-1} g^{-1}) \star d \star F \]
- **Divergence-free Constraint**:
  Logical consistency is maintained via source-free semantic flux:
  \[ \operatorname{div}_g (KX) = 0 \]
- **Adjoint Holonomy Update**:
  Parallel Key $K \in C^1(M, GL(D, \mathbb{R}))$ evolves via the commutator $\dot{K} = [\Omega, K]$:
  \[ K(t+dt) = H K(t) H^{-1}, \quad H = \exp(\Omega dt) \]

### 2. Postulated Theorems (Formal Definitions)
- **Theorem 1 (Logical Invariance)**: $\det(K)$ is a first integral ($\frac{d}{dt} \det(K) = 0$) under adjoint holonomy in Banach space.
- **Theorem 2 (Symmetry Breaking)**: Equivariant pitchfork bifurcation into discrete attractors $\{L_{high}, L_{mid}, L_{low}\}$ triggered by internal tension crossing $\mathcal{A}_c$.
- **Theorem 3 (Dimensional Resolution)**: Exponential convergence to low-energy equilibrium if $D \ge n$ (Orthogonal Embedding Lemma); persistent conflict if $D < n$.
- **Theorem 4 (Resonance)**: Commutativity $[K, F] \to 0$ in stable hierarchical states to minimize global dissipation.

---

## 🛠️ Build & Execution

### Prerequisites
- **Python 3.12+**
- **Fortran 95/2003** (`gfortran`)

### 1. Automated Reproduction (Recommended)
To install dependencies and run all simulation phases (Part 1-3) automatically:
```bash
chmod +x run_all.sh
./run_all.sh
```

### 2. Manual Execution
Individual simulations can be run within their respective directories:
```bash
# Python
pip install -r requirements.txt
python Part1/emergence_sim.py

# Fortran
cd Part1/
gfortran emergence_sim.f90 -o emergence_sim
./emergence_sim
```

### 3. Stability Analysis
To verify the numerical stability of the Euler scheme ($dt=0.1$) against RK4:
```bash
python Scripts/stability_analysis.py
```
*Observation: L2 error accumulated over 100 steps is $\approx 6.5 \times 10^{-5}$, justifying the use of first-order Euler on warped manifolds.*

---

## 📚 Core Reference & DOI

The theoretical foundation of this project is based on the following technical report:

**Miyata, F. (2026). "Parallel Key Geometric Flow in 12D Manifolds"**  
**DOI**: [10.5281/zenodo.19217632](https://doi.org/10.5281/zenodo.19217632)

---

## For full detailed analysis
- **[English Academic Paper](Docs/PKGF_Academic_Paper_en.md)**
- **[日本語学術論文](Docs/PKGF_Academic_Paper_jp.md)**

---
**Author**: Fumio Miyata (2026)  
**License**: For academic research purposes.
