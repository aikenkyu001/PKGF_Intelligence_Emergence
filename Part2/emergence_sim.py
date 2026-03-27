import math
import itertools
import sys
import random
import os

# ============================================================
# PKGF Intelligence Emergence Simulator (Part 2: N-Agents)
# Directory: /private/test/PKGF_Intelligence_Emergence/Part2/
# Goal: Emergence of Social Hierarchy and Group Dynamics
# ============================================================

DIM = 12
EPSILON_METRIC = 1e-5
EPSILON_MANIFOLD = 1e-4

# --- UTILS (Inherited from Part 1) ---

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

# --- CORE AGENT (N-Body Support) ---

class Agent:
    def __init__(self, name, x_init, K_init, idx, total_n):
        self.name, self.x, self.K = name, x_init, K_init
        self.idx, self.total_n = idx, total_n
        self.A_val, self.epsilon_K, self.hunger = 0.0, 0.0, 0.0
        self.C_vec = [1.0, 1.0, 0.0] # Id, Coh, Ten
        self.mode, self.reward = "Neutral", 0.0
        
        # 決定論的な個体差 (Personality Spectrum)
        ratio = idx / (total_n - 1)
        if ratio < 0.2: # Leader Class
            self.h_threshold, self.t_threshold, self.e_power = 0.2, 5.0, 0.01
        elif ratio < 0.5: # Middle Class
            self.h_threshold, self.t_threshold, self.e_power = 0.6, 1.2, 0.8
        else: # Follower Class
            self.h_threshold, self.t_threshold, self.e_power = 1.2, 0.6, 5.0

        # 第16要素: 社会的結合 (親和性スペクトル)
        # 自身とインデックスが近いほど「好き(>0)」、遠いほど「嫌い(<0)」
        self.affinities = []
        for j in range(total_n):
            diff = min(abs(idx - j), total_n - abs(idx - j))
            # 1.0 (親友) 〜 -1.0 (宿敵) のコサインカーブ
            val = math.cos(2.0 * math.pi * diff / total_n)
            self.affinities.append(val)

    def decide(self, world):
        # 好き嫌いに基づく緊張の再評価 (要素11: メタ認知)
        # 周囲に嫌いな奴が多いほど内的緊張を感じ、好きな奴がいれば緩和される
        social_stress = 0.0
        for o in world.agents:
            if o == self: continue
            dist = math.sqrt(sum((self.x[k]-o.x[k])**2 for k in range(DIM))) + 1e-9
            # 嫌いな奴の接近はストレス(正)、好きな奴はリラックス(負)
            social_stress += -self.affinities[o.idx] / (dist + 0.5)
        
        # 内的緊張場を社会的ストレスで補正
        ten = max(0, self.C_vec[2] + social_stress * 0.2)
        hng = self.hunger
        
        if hng > self.h_threshold: 
            self.mode = "Aggressive"
        elif ten > self.t_threshold:
            self.mode = "Submissive"
        else:
            self.mode = "Neutral"
        
        if self.reward > 0.1: self.hunger *= 0.5

    def get_v(self, world):
        def field_omega(pos):
            v_r = [(world.resource_pos[i] - pos[i]) * 0.4 for i in range(DIM)]
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
        d_w = 0.3 + self.hunger * 3.0
        v_des = [(world.resource_pos[i] - self.x[i]) * d_w for i in range(DIM)]
        
        # 第16要素による社会的流動の変調 (好き嫌い力学)
        v_eth = [0.0] * DIM
        norm_factor = 2.0 / len(world.agents)
        for o in world.agents:
            if o == self: continue
            diff = [self.x[k] - o.x[k] for k in range(DIM)]
            dist_sq = sum(d**2 for d in diff) + 1e-9
            
            # 親和性に基づく力の変換
            # aff > 0 (好き) -> 斥力が弱まり、ある程度で引力に転じる (追従・群れ)
            # aff < 0 (嫌い) -> 斥力が大幅に強化される (忌避・闘争)
            aff = self.affinities[o.idx]
            e_s = self.e_power * (1.5 - aff) 
            
            f = -e_s * norm_factor * (1.0 + self.C_vec[2]) / (dist_sq + 0.05)
            # 好きな相手には少しだけ近づこうとする項を追加
            if aff > 0.5: f += 0.2 * aff / (math.sqrt(dist_sq) + 1.0)
            
            for k in range(DIM): v_eth[k] += f * diff[k]
        
        eta = [random.uniform(-0.01, 0.01) for _ in range(DIM)]
        return [v_pkgf[i] + v_des[i] + world.l_base * v_eth[i] + eta[i] for i in range(DIM)]

    def update(self, v, dt, world):
        d_p = math.sqrt(sum((self.x[i] - world.resource_pos[i])**2 for i in range(DIM)))
        self.x = [self.x[i] + v[i] * dt for i in range(DIM)]
        d_c = math.sqrt(sum((self.x[i] - world.resource_pos[i])**2 for i in range(DIM)))
        self.K = parallel_transport_key(self.K, self.x, v, dt)
        
        ex = 1.2 * max(0, (d_c - d_p)/dt) + 0.4 * math.sqrt(sum(vi**2 for vi in v))
        self.A_val = max(0, min(5.0, self.A_val + (-0.6 * self.A_val + ex) * dt))
        self.epsilon_K = 0.06 * self.A_val
        for i in range(DIM): self.K[i][i] += random.uniform(-0.005, 0.005) * self.A_val
        
        tau = 0.35
        self.C_vec[0] += (-tau * self.C_vec[0] + math.tanh(2.0 * self.C_vec[0] + 1.0/(1.0+self.A_val))) * dt
        self.C_vec[1] += (-tau * self.C_vec[1] + math.tanh(2.0 * self.C_vec[1] + 1.0/(1.0+self.epsilon_K))) * dt
        self.C_vec[2] += (-tau * self.C_vec[2] + math.tanh(self.A_val * 1.3)) * dt
        self.C_vec = [max(0, min(2.0, val)) for val in self.C_vec]
        
        if d_c < 0.4: self.reward += 0.4 / (1.0 + self.A_val)
        else: self.hunger += 0.15 * dt

class World:
    def __init__(self, num_agents=15):
        self.agents = []
        self.resource_pos = [0.0]*DIM
        self.l_base = 0.4
        self.dt = 0.1
        K_init = identity_matrix()
        for i in range(num_agents):
            # 初期配置もインデックスに基づいて決定論的に
            angle = 2 * math.pi * i / num_agents
            pos = [0.0] * DIM
            pos[0], pos[1] = 2.0 * math.cos(angle), 2.0 * math.sin(angle)
            self.agents.append(Agent(f"A_{i:02d}", pos, [r[:] for r in K_init], i, num_agents))

    def step(self):
        v_list = [a.get_v(self) for a in self.agents]
        for a in self.agents: a.decide(self)
        for a, v in zip(self.agents, v_list): a.update(v, self.dt, self)

# --- EXPERIMENTS ---

def run_part2_experiments():
    log_dir = "/private/test/PKGF_Intelligence_Emergence/Part2/logs/python"
    os.makedirs(log_dir, exist_ok=True)
    
    # PHASE D: Group Stability (N=15, No Decision)
    with Tee(f"{log_dir}/phase_D_group_stability.txt"):
        print("=== Phase D: Group Stability (N=15) ===")
        w = World(num_agents=15)
        for a in w.agents: a.decide = lambda world: None # 静的な均衡を確認
        print(f"{'Step':<5} | {'Avg_Dist':<10} | {'Sum_Rew':<10}")
        for s in range(51):
            avg_dist = sum(math.sqrt(sum(a.x[i]**2 for i in range(DIM))) for a in w.agents) / 15
            sum_rew = sum(a.reward for a in w.agents)
            if s % 10 == 0: print(f"{s:<5} | {avg_dist:10.5f} | {sum_rew:10.5f}")
            w.step()

    # PHASE E: Social Hierarchy Emergence (N=15)
    with Tee(f"{log_dir}/phase_E_hierarchy.txt"):
        print("\n=== Phase E: Three-Layer Hierarchy Emergence (N=15) ===")
        w = World(num_agents=15)
        print(f"{'Step':<5} | {'Modes (A/N/S)':<15} | {'Avg_Rew':<10} | {'Power_Grad':<10}")
        for s in range(301): # 観測時間を延長
            modes = [a.mode[0] for a in w.agents]
            counts = f"{modes.count('A')}/{modes.count('N')}/{modes.count('S')}"
            rewards = [a.reward for a in w.agents]
            mean_r = sum(rewards)/len(rewards) + 1e-9
            var_r = sum((r - mean_r)**2 for r in rewards) / len(rewards)
            power_grad = var_r / mean_r
            if s % 30 == 0: print(f"{s:<5} | {counts:<15} | {mean_r:10.4f} | {power_grad:10.5f}")
            w.step()
        
        print("\n[Final Multi-Layer Status]")
        # 報酬順にソートして階層を表示
        sorted_agents = sorted(w.agents, key=lambda a: a.reward, reverse=True)
        for a in sorted_agents:
            print(f"{a.name}: Mode={a.mode:<10}, Reward={a.reward:8.4f}, Tension={a.C_vec[2]:.3f}")

if __name__ == "__main__":
    run_part2_experiments()
