#!/bin/bash
# PKGF Intelligence Emergence - Master Reproduction Script
# Author: Fumio Miyata (2026)
# Description: Executes all simulation phases (Part 1, 2, 3) and generates logs.

set -e

echo "Starting PKGF Intelligence Emergence Reproducibility Suite..."

# 1. Environment Setup
echo "Checking Python environment..."
pip install -r requirements.txt --quiet

# 2. Part 1: 2-Body Symmetry Breaking
echo "Running Part 1: Symmetry Breaking (2-Agent)..."
cd Part1
python emergence_sim.py
cd ..

# 3. Part 2: 15-Body Social Hierarchy
echo "Running Part 2: Social Hierarchy (15-Agent)..."
cd Part2
python emergence_sim.py
cd ..

# 4. Part 3: Dimensional Comparison
echo "Running Part 3: Dimensional Resolution (N=4, 8, 16)..."
cd Part3
python emergence_sim.py
cd ..

echo "All simulations completed successfully. Logs are available in Part*/logs/."
