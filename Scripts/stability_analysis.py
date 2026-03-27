import numpy as np
import matplotlib.pyplot as plt

# Simplified PKGF flow for stability analysis
# Equation: v = -K^-1 * grad(Omega)
# For stability, we test a simple harmonic-like semantic potential

DIM = 12
dt = 0.1
STEPS = 100

def get_v(x, K):
    # grad(Omega) = x (harmonic attraction to origin)
    grad_omega = x
    # Simple Parallel Key (Identity for baseline)
    v = -np.dot(np.linalg.inv(K), grad_omega)
    return v

def euler_step(x, K, dt):
    v = get_v(x, K)
    return x + v * dt

def rk4_step(x, K, dt):
    k1 = get_v(x, K)
    k2 = get_v(x + 0.5 * dt * k1, K)
    k3 = get_v(x + 0.5 * dt * k2, K)
    k4 = get_v(x + dt * k3, K)
    return x + (dt / 6.0) * (k1 + 2*k2 + 2*k3 + k4)

# Initial conditions
x0 = np.array([1.0] * DIM)
K = np.eye(DIM)

# Euler trajectory
x_euler = [x0]
for _ in range(STEPS):
    x_euler.append(euler_step(x_euler[-1], K, dt))

# RK4 trajectory
x_rk4 = [x0]
for _ in range(STEPS):
    x_rk4.append(rk4_step(x_rk4[-1], K, dt))

x_euler = np.array(x_euler)
x_rk4 = np.array(x_rk4)

# Error analysis
error = np.linalg.norm(x_euler - x_rk4, axis=1)

plt.figure(figsize=(10, 5))
plt.plot(error, label='Euler vs RK4 (L2 Error)')
plt.title('Numerical Stability Analysis (dt=0.1)')
plt.xlabel('Step')
plt.ylabel('L2 Difference')
plt.yscale('log')
plt.grid(True)
plt.legend()
plt.savefig('Scripts/stability_analysis.png')

print(f"Final Error (Step {STEPS}): {error[-1]:.2e}")
print("Stability analysis plot saved to Scripts/stability_analysis.png")
