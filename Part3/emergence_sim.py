import math
import sys
import random
import os

# ============================================================
# PKGF Intelligence Emergence Simulator (Part 3: Dynamic Dimensions)
# Directory: /private/test/PKGF_Intelligence_Emergence/Part3/
# Goal: Comparison of N=DIM={4, 8, 16}
# ============================================================

# --- MATRIX UTILS (N-DIM Generalized) ---

def identity_matrix(n): return [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
def zero_matrix(n): return [[0.0 for _ in range(n)] for _ in range(n)]
def mat_mul(A, B, n):
    C = zero_matrix(n)
    for i in range(n):
        for k in range(n):
            if abs(A[i][k]) > 1e-18:
                aik = A[i][k]
                for j in range(n): C[i][j] += aik * B[k][j]
    return C
def mat_inv(A, n):
    res = identity_matrix(n)
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

def matrix_exp_pade(A, n):
    inf_norm = max(sum(abs(x) for x in row) for row in A)
    k = max(0, math.ceil(math.log2(inf_norm / 0.5))) if inf_norm > 0 else 0
    A_s = [[x / (2**k) for x in row] for row in A]
    c = [1.0, 0.5, 0.1, 0.01111111111111111, 0.0007575757575757576, 3.0303030303030303e-05, 5.050505050505051e-07]
    P, Q, A_p = identity_matrix(n), identity_matrix(n), identity_matrix(n)
    for i in range(1, 7):
        A_p = mat_mul(A_p, A_s, n)
        term = [[x * c[i] for x in row] for row in A_p]
        for r in range(n):
            for col in range(n):
                P[r][col] += term[r][col]
                if i % 2 == 0: Q[r][col] += term[r][col]
                else:          Q[r][col] -= term[r][col]
    res = mat_mul(mat_inv(Q, n), P, n)
    for _ in range(k): res = mat_mul(res, res, n)
    return res

# --- GEOMETRY ---

def get_metric_tensor(x, n):
    g = zero_matrix(n)
    # Contextual Warping: DIMを4セクターに分けて計量を変調
    # 最後の1/4セクターをContextとする
    ctx_idx = (n * 3) // 4
    s = [1.0 + 0.5 * math.tanh(x[i]) for i in range(ctx_idx, n)]
    avg_ctx = sum(s) / len(s) if s else 1.0
    for i in range(n):
        if i < ctx_idx: g[i][i] = avg_ctx
        else: g[i][i] = 1.0
    return g

def compute_christoffel_symbols(x, n):
    eps = 1e-5
    g_inv = mat_inv(get_metric_tensor(x, n), n)
    partials = []
    for k in range(n):
        xp, xm = x[:], x[:]; xp[k] += eps; xm[k] -= eps
        gp, gm = get_metric_tensor(xp, n), get_metric_tensor(xm, n)
        diff = [[(gp[i][j] - gm[i][j]) * 0.5 / eps for j in range(n)] for i in range(n)]
        partials.append(diff)
    Gamma = [[[0.0 for _ in range(n)] for _ in range(n)] for _ in range(n)]
    for k in range(n):
        for i in range(n):
            for j in range(n):
                val = 0.0
                for l in range(n):
                    val += g_inv[k][l] * (partials[i][j][l] + partials[j][i][l] - partials[l][i][j])
                Gamma[k][i][j] = 0.5 * val
    return Gamma

def parallel_transport_key(K, x, v_dt, dt, n):
    G = compute_christoffel_symbols(x, n); Omega = zero_matrix(n)
    for i in range(n):
        for j in range(n): Omega[i][j] = sum(G[i][k][j] * v_dt[k] for k in range(n))
    H = matrix_exp_pade([[val * dt for val in row] for row in Omega], n)
    return mat_mul(mat_mul(H, K, n), mat_inv(H, n), n)

# --- CORE AGENT ---

class Agent:
    def __init__(self, name, x_init, K_init, idx, n, dim):
        self.name, self.x, self.K = name, x_init, K_init
        self.idx, self.n, self.dim = idx, n, dim
        self.A_val, self.hunger, self.reward = 0.0, 0.0, 0.0
        self.C_vec = [1.0, 1.0, 0.0]
        self.mode = "Neutral"
        
        # 性格勾配
        ratio = idx / (n - 1)
        if ratio < 0.2: self.h_threshold, self.t_threshold, self.e_power = 0.2, 5.0, 0.01
        elif ratio < 0.5: self.h_threshold, self.t_threshold, self.e_power = 0.6, 1.2, 0.8
        else: self.h_threshold, self.t_threshold, self.e_power = 1.2, 0.6, 5.0

        # 親和性
        self.affinities = [math.cos(2.0 * math.pi * min(abs(idx-j), n-abs(idx-j)) / n) for j in range(n)]

    def decide(self, world):
        stress = 0.0
        for o in world.agents:
            if o == self: continue
            dist = math.sqrt(sum((self.x[k]-o.x[k])**2 for k in range(self.dim))) + 1e-9
            stress += -self.affinities[o.idx] / (dist + 0.5)
        
        ten = max(0, self.C_vec[2] + stress * 0.2)
        if self.hunger > self.h_threshold: self.mode = "Aggressive"
        elif ten > self.t_threshold: self.mode = "Submissive"
        else: self.mode = "Neutral"
        if self.reward > 0.1: self.hunger *= 0.5

    def get_v(self, world):
        dim = self.dim
        def field_omega(p):
            v_r = [(world.resource_pos[i] - p[i]) * 0.4 for i in range(dim)]
            g = get_metric_tensor(p, dim)
            return [sum(g[i][j] * v_r[j] for j in range(dim)) for i in range(dim)]
        
        # Co-differential Approximation
        omega_x = field_omega(self.x); eps = 1e-4; v_pkgf = [0.0]*dim
        for i in range(dim):
            pp = self.x[:]; pp[i] += eps; omega_p = field_omega(pp)
            for j in range(dim): v_pkgf[j] += (omega_p[j] - omega_x[j]) / eps # Simplification
        
        d_w = 0.3 + self.hunger * 3.0
        v_des = [(world.resource_pos[i] - self.x[i]) * d_w for i in range(dim)]
        
        v_eth = [0.0] * dim
        norm_factor = 2.0 / self.n
        for o in world.agents:
            if o == self: continue
            diff = [self.x[k] - o.x[k] for k in range(dim)]
            dist_sq = sum(d**2 for d in diff) + 1e-9
            aff = self.affinities[o.idx]
            e_s = self.e_power * (1.5 - aff)
            if self.mode == "Aggressive": e_s *= 0.01
            elif self.mode == "Submissive": e_s *= 2.0
            
            f = -e_s * norm_factor * (1.0 + self.C_vec[2]) / (dist_sq + 0.05)
            if aff > 0.5: f += 0.2 * aff / (math.sqrt(dist_sq) + 1.0)
            for k in range(dim): v_eth[k] += f * diff[k]
        
        eta = [random.uniform(-0.01, 0.01) for _ in range(dim)]
        return [v_pkgf[i] + v_des[i] + world.l_base * v_eth[i] + eta[i] for i in range(dim)]

    def update(self, v, dt, world):
        dim = self.dim
        d_p = math.sqrt(sum((self.x[i] - world.resource_pos[i])**2 for i in range(dim)))
        self.x = [self.x[i] + v[i] * dt for i in range(dim)]
        d_c = math.sqrt(sum((self.x[i] - world.resource_pos[i])**2 for i in range(dim)))
        self.K = parallel_transport_key(self.K, self.x, v, dt, dim)
        
        ex = 1.2 * max(0, (d_c - d_p)/dt) + 0.4 * math.sqrt(sum(vi**2 for vi in v))
        self.A_val = max(0, min(5.0, self.A_val + (-0.6 * self.A_val + ex) * dt))
        for i in range(dim): self.K[i][i] += random.uniform(-0.005, 0.005) * self.A_val
        
        tau = 0.35
        self.C_vec[2] += (-tau * self.C_vec[2] + math.tanh(self.A_val * 1.3)) * dt
        self.C_vec[2] = max(0, min(2.0, self.C_vec[2]))
        
        if d_c < 0.4: self.reward += 0.4 / (1.0 + self.A_val)
        else: self.hunger += 0.15 * dt

class World:
    def __init__(self, n):
        self.n, self.dim, self.agents = n, n, []
        self.resource_pos = [0.0]*n
        self.l_base, self.dt = 0.4, 0.1
        K_init = identity_matrix(n)
        for i in range(n):
            pos = [(random.random()-0.5)*2.0 for _ in range(n)]
            self.agents.append(Agent(f"A_{i:02d}", pos, [r[:] for r in K_init], i, n, n))
    def step(self):
        v_list = [a.get_v(self) for a in self.agents]
        for a in self.agents: a.decide(self)
        for a, v in zip(self.agents, v_list): a.update(v, self.dt, self)

# --- EXPERIMENTS ---

def run_experiment(n):
    print(f"\n--- Case: N={n}, DIM={n} ---")
    w = World(n)
    print(f"{'Step':<5} | {'Modes (A/N/S)':<15} | {'Avg_Rew':<10} | {'Avg_Ten':<10}")
    for s in range(201):
        modes = [a.mode[0] for a in w.agents]
        counts = f"{modes.count('A')}/{modes.count('N')}/{modes.count('S')}"
        rewards = [a.reward for a in w.agents]
        tensions = [a.C_vec[2] for a in w.agents]
        avg_r = sum(rewards)/n; avg_t = sum(tensions)/n
        if s % 40 == 0: print(f"{s:<5} | {counts:<15} | {avg_r:10.4f} | {avg_t:10.4f}")
        w.step()
    return avg_t

if __name__ == "__main__":
    log_dir = "/private/test/PKGF_Intelligence_Emergence/Part3/logs/python"
    os.makedirs(log_dir, exist_ok=True)
    sys.stdout = open(f"{log_dir}/phase_G_dimension_comparison.txt", "w")
    for n in [4, 8, 16]:
        run_experiment(n)
