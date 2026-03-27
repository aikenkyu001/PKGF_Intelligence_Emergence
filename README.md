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
│   ├── PKGF_Academic_Paper_jp.md  # Full Japanese paper
│   └── PKGF_Academic_Paper_en.md  # Full English paper (Native)
├── Part1/              # Phase A-C: 2-body symmetry breaking simulations
│   ├── emergence_sim.f90  # Fortran 95 implementation
│   ├── emergence_sim.py   # Python 3.12 implementation
│   └── logs/              # Stability, deadlock, and emergence logs
├── Part2/              # Phase D-E: 15-body social hierarchy simulations
│   ├── emergence_sim.f90  
│   ├── emergence_sim.py   
│   └── logs/              # Group stability and hierarchy formation logs
├── Part3/              # Phase G: N-body dimensional comparison simulations
│   ├── emergence_sim.f90  
│   ├── emergence_sim.py   
│   └── logs/              # Dimensionality vs. Tension logs (N=4, 8, 16)
└── PDF/                # Collected scientific references (Ricci Flow, Higher Gauge Theory, etc.)
```

---

## 🧠 Mathematical Foundations

### 1. Fundamental Equations
- **Co-differential Propulsion**:
  Meaning flow $v$ is propelled by the co-differential ($\delta F$) of a 2-form $F = d\omega$:
  \[ \frac{\partial}{\partial t}(KX)^\flat = -\delta F = -\star d \star F \]
- **Divergence-free Constraint**:
  To maintain logical consistency, the flux $KX$ is always kept source-free:
  \[ \operatorname{div}_g (KX) = 0 \]
- **Adjoint Holonomy Update**:
  Logical structure $K$ evolves via the connection matrix $\Omega$:
  \[ K(t+dt) = H K(t) H^{-1}, \quad H = \exp(\Omega dt) \]

### 2. The 16 Elements of Intelligence
Intelligence is modeled as a coupled system of 16 interacting fields:
1. Meaning | 2. Context | 3. Metric $g$ | 4. Transformation $K$ | 5. Desire $D$ | 6. Ethics $E$ | 7. Emotion $A$ | 8. Value Shaping | 9. Learning | 10. Memory $H$ | 11. Meta-cognition | 12. Meta-update | 13. Self-reference | 14. Consciousness | 15. Strategy | 16. Social Coupling

### 3. Postulated Theorems
- **Theorem 1 (Logical Invariance)**: $\det(K)$ is invariant under adjoint holonomy updates.
- **Theorem 2 (Symmetry Breaking)**: Systems bifurcate into discrete attractors when internal tension exceeds $\mathcal{A}_c$.
- **Theorem 3 (Dimensional Resolution)**: Higher-dimensional manifolds ($D \ge N$) resolve conflicts (Peaceful Silence).
- **Theorem 4 (Resonance)**: Social order corresponds to the commutation $[K, F] \to 0$.

---

## 🛠️ Build & Execution

### Prerequisites
- **Python 3.12+** (NumPy, SciPy, Matplotlib)
- **Fortran 95/2003** (`gfortran` or equivalent compiler)

### 1. Fortran Simulations
To compile and run the numerical simulations in any `Part` directory:
```bash
cd Part1/  # or Part2/, Part3/
gfortran emergence_sim.f90 -o emergence_sim
./emergence_sim
```

### 2. Python Simulations
To run the high-level logic and visualization scripts:
```bash
cd Part1/  # or Part2/, Part3/
pip install numpy scipy matplotlib
python emergence_sim.py
```

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
