import math
import itertools
import sys
import random
import os

# ============================================================
# PKGF Intelligence Emergence Simulator (Integrated Edition)
# Directory: /private/test/PKGF_Intelligence_Emergence/
# Multi-Phase Logging Enabled
# ============================================================

DIM = 12
EPSILON_METRIC = 1e-5
EPSILON_MANIFOLD = 1e-4

# --- UTILS ---

def identity_matrix(): return [[1.0 if i == j else 0.0 for j in range(DIM)] for i in range(DIM)]
def zero_matrix(): return [[0.0 for _ in range(DIM)] for _ in range(DIM)]
def mat_mul(A, B):
    C = zero_matrix()
    for i in range(DIM):
        for k in range(DIM):
            if abs(A[i][k]) > 1e-18:
                aik = A[i][k]
                for j in range(DIM): C[i][j] += aik * B[k][j]
    return C
def mat_inv(A):
    n = len(A)
    res = identity_matrix()
    m = [row[:] + res[i] for i, row in enumerate(A)]
    for i in range(n):
        pivot = m[i][i]
        if abs(pivot) < 1e-18:
            for k in range(i+1, n):
                if abs(m[k][i]) > abs(pivot):
                    m[i], m[k] = m[k], m[i]
                    pivot = m[i][i]; break
        if abs(pivot) < 1e-18: continue
        inv_p = 1.0 / pivot
        for j in range(2*n): m[i][j] *= inv_p
        for k in range(n):
            if i != k:
                f = m[k][i]
                for j in range(2*n): m[k][j] -= f * m[i][j]
    return [row[n:] for row in m]

def calculate_det_12x12(M):
    n, lu, det = len(M), [row[:] for row in M], 1.0
    for i in range(n):
        pivot = lu[i][i]
        if abs(pivot) < 1e-15:
            for k in range(i+1, n):
                if abs(lu[k][i]) > abs(pivot):
                    lu[i], lu[k] = lu[k], lu[i]; det *= -1; pivot = lu[i][i]; break
            if abs(pivot) < 1e-15: return 0.0
        det *= pivot
        for k in range(i+1, n):
            factor = lu[k][i] / pivot
            for j in range(i+1, n): lu[k][j] -= factor * lu[i][j]
    return det

def matrix_exp_pade(A):
    inf_norm = max(sum(abs(x) for x in row) for row in A)
    k = max(0, math.ceil(math.log2(inf_norm / 0.5))) if inf_norm > 0 else 0
    A_s = [[x / (2**k) for x in row] for row in A]
    c = [1.0, 0.5, 0.1, 0.01111111111111111, 0.0007575757575757576, 3.0303030303030303e-05, 5.050505050505051e-07]
    P, Q, A_p = identity_matrix(), identity_matrix(), identity_matrix()
    for i in range(1, 7):
        A_p = mat_mul(A_p, A_s)
        term = [[x * c[i] for x in row] for row in A_p]
        for r in range(DIM):
            for c_idx in range(DIM):
                P[r][c_idx] += term[r][c_idx]
                if i % 2 == 0: Q[r][c_idx] += term[r][c_idx]
                else:          Q[r][c_idx] -= term[r][c_idx]
    res = mat_mul(mat_inv(Q), P)
    for _ in range(k): res = mat_mul(res, res)
    return res

# --- GEOMETRY ---

def get_metric_tensor(x):
    g = zero_matrix()
    s = [1.0 + 0.5 * math.tanh(x[9+i]) for i in range(3)]
    for i in range(DIM):
        if i < 3: g[i][i] = s[0]
        elif i < 6: g[i][i] = s[1]
        elif i < 9: g[i][i] = s[2]
        else: g[i][i] = 1.0
    return g

def compute_christoffel_symbols(x):
    g = get_metric_tensor(x); g_inv = mat_inv(g)
    partials = []
    for k in range(DIM):
        xp, xm = x[:], x[:]; xp[k] += EPSILON_METRIC; xm[k] -= EPSILON_METRIC
        diff = [[(p - m) * 0.5 / EPSILON_METRIC for p, m in zip(rp, rm)] for rp, rm in zip(get_metric_tensor(xp), get_metric_tensor(xm))]
        partials.append(diff)
    Gamma = [[[0.0 for _ in range(DIM)] for _ in range(DIM)] for _ in range(DIM)]
    for k in range(DIM):
        for i in range(DIM):
            for j in range(DIM):
                val = 0.0
                for l in range(DIM):
                    if abs(g_inv[k][l]) > 1e-9:
                        val += g_inv[k][l] * (partials[i][j][l] + partials[j][i][l] - partials[l][i][j])
                Gamma[k][i][j] = 0.5 * val
    return Gamma

def co_differential_2form(F_field_func, x):
    # 軽量化した推進力の近似計算 (知性の創発に特化)
    eps = EPSILON_MANIFOLD
    F_x = F_field_func(x)
    div_F = [0.0] * DIM
    for i in range(DIM):
        xp = x[:]; xp[i] += eps
        F_p = F_field_func(xp)
        for j in range(DIM):
            div_F[j] += (F_p[i][j] - F_x[i][j]) / eps
    return div_F

def parallel_transport_key(K, x, v_dt, dt):
    G = compute_christoffel_symbols(x); Omega = zero_matrix()
    for i in range(DIM):
        for j in range(DIM): Omega[i][j] = sum(G[i][k][j] * v_dt[k] for k in range(DIM))
    H = matrix_exp_pade([[val * dt for val in row] for row in Omega])
    return mat_mul(mat_mul(H, K), mat_inv(H))

# --- LOGGING ---

class Tee(object):
    def __init__(self, name):
        self.file = open(name, "w", encoding="utf-8")
        self.stdout = sys.stdout
    def __enter__(self):
        sys.stdout = self
        return self
    def __exit__(self, type, value, traceback):
        sys.stdout = self.stdout
        self.file.close()
    def write(self, data):
        self.file.write(data)
        self.stdout.write(data)
    def flush(self):
        self.file.flush()
        self.stdout.flush()

# --- CORE AGENT ---

class Agent:
    def __init__(self, name, x_init, K_init):
        self.name, self.x, self.K = name, x_init, K_init
        self.A_val, self.epsilon_K, self.hunger = 0.0, 0.0, 0.0
        self.C_vec = [1.0, 1.0, 0.0] # Id, Coh, Ten
        self.mode, self.reward = "Neutral", 0.0

    def decide(self, world):
        if self.mode == "Neutral":
            if self.C_vec[2] > 1.0 or self.hunger > 0.5:
                other_mode = "Neutral"
                for o in world.agents:
                    if o != self: other_mode = o.mode
                p_agg = 0.1 if other_mode == "Aggressive" else (0.9 if other_mode == "Submissive" else 0.5)
                self.mode = "Aggressive" if random.random() < p_agg else "Submissive"
        if self.reward > 0.5: self.hunger *= 0.5

    def get_v(self, world):
        def field_omega(pos):
            v_r = [(world.resource_pos[i] - pos[i]) * 0.5 for i in range(DIM)]
            g = get_metric_tensor(pos)
            return [sum(g[i][j] * v_r[j] for j in range(DIM)) for i in range(DIM)]
        def F_func(p):
            eps = 1e-4; omega_x = field_omega(p); F = zero_matrix()
            for i in range(DIM):
                pp = p[:]; pp[i] += eps; omega_p = field_omega(pp)
                for j in range(DIM): F[i][j] = (omega_p[j] - omega_x[j]) / eps
            for i in range(DIM):
                for j in range(DIM): F[i][j] = F[i][j] - F[j][i]
            return F
        
        v_pkgf = co_differential_2form(F_func, self.x)
        d_w = 0.5 + self.hunger * 1.5
        v_des = [(world.resource_pos[i] - self.x[i]) * d_w for i in range(DIM)]
        v_eth = [0.0] * DIM
        e_s = 0.05 if self.mode == "Aggressive" else (3.0 if self.mode == "Submissive" else 1.0)
        for o in world.agents:
            if o == self: continue
            diff = [self.x[i] - o.x[i] for i in range(DIM)]
            dist_sq = sum(d**2 for d in diff) + 1e-9
            f = -e_s * (1.2 + self.C_vec[2]) / (dist_sq + 0.1) # 正則化
            for i in range(DIM): v_eth[i] += f * diff[i]
        
        eta = [random.uniform(-0.02, 0.02) * (1.0 + self.A_val) for _ in range(DIM)]
        return [v_pkgf[i] + v_des[i] + world.l_base * v_eth[i] + eta[i] for i in range(DIM)]

    def update(self, v, dt, world):
        d_p = math.sqrt(sum((self.x[i] - world.resource_pos[i])**2 for i in range(DIM)))
        self.x = [self.x[i] + v[i] * dt for i in range(DIM)]
        d_c = math.sqrt(sum((self.x[i] - world.resource_pos[i])**2 for i in range(DIM)))
        self.K = parallel_transport_key(self.K, self.x, v, dt)
        
        # Internal
        ex = 1.2 * max(0, (d_c - d_p)/dt) + 0.3 * math.sqrt(sum(vi**2 for vi in v))
        self.A_val = max(0, min(5.0, self.A_val + (-0.5 * self.A_val + ex) * dt))
        self.epsilon_K = 0.05 * self.A_val
        for i in range(DIM): self.K[i][i] += random.uniform(-0.005, 0.005) * self.A_val
        
        tau = 0.3
        self.C_vec[0] += (-tau * self.C_vec[0] + math.tanh(2.0 * self.C_vec[0] + 1.0/(1.0+self.A_val))) * dt
        self.C_vec[1] += (-tau * self.C_vec[1] + math.tanh(2.0 * self.C_vec[1] + 1.0/(1.0+self.epsilon_K))) * dt
        self.C_vec[2] += (-tau * self.C_vec[2] + math.tanh(self.A_val * 1.2)) * dt
        self.C_vec = [max(0, min(2.0, val)) for val in self.C_vec]
        
        if d_c < 0.4: self.reward += 0.3 / (1.0 + self.A_val)
        else: self.hunger += 0.1 * dt

class World:
    def __init__(self):
        self.agents, self.resource_pos, self.l_base, self.dt = [], [0.0]*DIM, 0.25, 0.1
    def step(self):
        v_list = [a.get_v(self) for a in self.agents]
        for a in self.agents: a.decide(self)
        for a, v in zip(self.agents, v_list): a.update(v, self.dt, self)

# --- PHASES ---

def run_experiment_phases():
    log_dir = "/private/test/PKGF_Intelligence_Emergence/logs/python"
    os.makedirs(log_dir, exist_ok=True)
    
    K_init = identity_matrix()

    # PHASE A: Basic Stability (Single Agent)
    with Tee(f"{log_dir}/phase_A_stability.txt"):
        print("=== Phase A: Basic Stability (Single Agent) ===")
        w = World(); a = Agent("Alpha", [1.0] + [0.0]*11, [r[:] for r in K_init])
        w.agents = [a]
        print(f"{'Step':<5} | {'Pos[0]':<10} | {'det(K)':<10} | {'Reward':<10}")
        for s in range(51):
            if s % 10 == 0: print(f"{s:<5} | {a.x[0]:10.5f} | {calculate_det_12x12(a.K):10.5f} | {a.reward:10.5f}")
            w.step()

    # PHASE B: Social Deadlock (Symmetric)
    with Tee(f"{log_dir}/phase_B_deadlock.txt"):
        print("\n=== Phase B: Social Deadlock (Symmetric) ===")
        w = World(); a1 = Agent("Alpha", [0.8] + [0.0]*11, [r[:] for r in K_init]); a2 = Agent("Beta", [-0.8] + [0.0]*11, [r[:] for r in K_init])
        w.agents = [a1, a2]
        # 戦略決定を一時無効にして物理的な均衡を見る
        a1.decide = lambda world: None; a2.decide = lambda world: None
        print(f"{'Step':<5} | {'A1_Pos':<10} | {'A2_Pos':<10} | {'Dist':<10}")
        for s in range(51):
            dist = math.sqrt(sum((a1.x[i]-a2.x[i])**2 for i in range(DIM)))
            if s % 10 == 0: print(f"{s:<5} | {a1.x[0]:10.5f} | {a2.x[0]:10.5f} | {dist:10.5f}")
            w.step()

    # PHASE C: Strategic Emergence (The Final Goal)
    with Tee(f"{log_dir}/phase_C_emergence.txt"):
        print("\n=== Phase C: Strategic Emergence (Intelligence) ===")
        w = World(); a1 = Agent("Alpha", [0.8] + [0.0]*11, [r[:] for r in K_init]); a2 = Agent("Beta", [-0.8] + [0.0]*11, [r[:] for r in K_init])
        w.agents = [a1, a2]
        print(f"{'Step':<5} | {'A1_Mode':<10} | {'A2_Mode':<10} | {'A1_Rew':<10} | {'A2_Rew':<10} | {'A1_Ten':<6}")
        for s in range(151):
            if s % 15 == 0: print(f"{s:<5} | {a1.mode:<10} | {a2.mode:<10} | {a1.reward:10.4f} | {a2.reward:10.4f} | {a1.C_vec[2]:.3f}")
            w.step()
        
        print("\n[Final Emergence Check]")
        print(f"Alpha: {a1.mode}, Beta: {a2.mode}")
        if a1.mode != a2.mode: print("RESULT: SUCCESS - Role Division Emerged.")
        else: print("RESULT: SYMMETRIC - Re-run or adjust bifurcation parameters.")

if __name__ == "__main__":
    run_experiment_phases()
