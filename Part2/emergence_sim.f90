program emergence_sim_fortran_nbody
    use, intrinsic :: iso_fortran_env, only: real64, int32
    implicit none

    integer, parameter :: DIM = 12
    integer, parameter :: N_MAX = 15
    real(real64), parameter :: EPSILON_METRIC = 1e-5
    real(real64), parameter :: EPSILON_MANIFOLD = 1e-4
    real(real64), parameter :: DT = 0.1_real64
    real(real64), parameter :: PI = 3.1415926535897932_real64

    type :: Agent
        character(len=10) :: name
        integer :: idx
        real(real64) :: x(DIM)
        real(real64) :: K(DIM, DIM)
        real(real64) :: A_val, epsilon_K, hunger
        real(real64) :: C_vec(3)
        real(real64) :: reward
        character(len=12) :: mode
        ! 性格パラメータ (Traits)
        real(real64) :: h_threshold, t_threshold, e_power
        ! 第16要素: 親和性 (Affinities)
        real(real64) :: affinities(N_MAX)
    end type Agent

    type :: World
        type(Agent), allocatable :: agents(:)
        real(real64) :: resource_pos(DIM)
        real(real64) :: l_base
    end type World

    type(World) :: w
    integer, parameter :: LOG_UNIT = 15

    call execute_phases_part2()

contains

    subroutine execute_phases_part2()
        character(len=256) :: log_dir = "/private/test/PKGF_Intelligence_Emergence/Part2/logs/fortran"
        character(len=256) :: log_path
        
        log_path = trim(log_dir) // "/phase_D_group_stability.txt"
        open(unit=LOG_UNIT, file=trim(log_path), status='replace', action='write')
        call run_phase_D()
        close(LOG_UNIT)
        
        log_path = trim(log_dir) // "/phase_E_hierarchy.txt"
        open(unit=LOG_UNIT, file=trim(log_path), status='replace', action='write')
        call run_phase_E()
        close(LOG_UNIT)
    end subroutine execute_phases_part2

    subroutine run_phase_D()
        integer :: s, i
        real(real64) :: avg_dist, sum_rew
        write(LOG_UNIT, *) "=== Phase D: Group Stability (N=15) ==="
        write(*, *) "=== Phase D: Group Stability (N=15) ==="
        call init_world_n(N_MAX)
        do s = 0, 50
            avg_dist = 0.0_real64; sum_rew = 0.0_real64
            do i = 1, N_MAX
                avg_dist = avg_dist + sqrt(sum(w%agents(i)%x**2))
                sum_rew = sum_rew + w%agents(i)%reward
            end do
            avg_dist = avg_dist / real(N_MAX, real64)
            if (mod(s, 10) == 0) then
                write(LOG_UNIT, '(I5, " | ", F10.5, " | ", F10.5)') s, avg_dist, sum_rew
                write(*, '(I5, " | ", F10.5, " | ", F10.5)') s, avg_dist, sum_rew
            end if
            call world_step_n(.false.)
        end do
    end subroutine run_phase_D

    subroutine run_phase_E()
        integer :: s, i, a_count, n_count, s_count
        real(real64) :: rewards(N_MAX), mean_r, var_r, p_grad
        write(LOG_UNIT, *) "=== Phase E: Three-Layer Hierarchy Emergence (N=15) ==="
        write(*, *) "=== Phase E: Three-Layer Hierarchy Emergence (N=15) ==="
        call init_world_n(N_MAX)
        do s = 0, 300
            a_count = 0; n_count = 0; s_count = 0
            do i = 1, N_MAX
                if (trim(w%agents(i)%mode) == "Aggressive") a_count = a_count + 1
                if (trim(w%agents(i)%mode) == "Neutral") n_count = n_count + 1
                if (trim(w%agents(i)%mode) == "Submissive") s_count = s_count + 1
                rewards(i) = w%agents(i)%reward
            end do
            mean_r = sum(rewards)/real(N_MAX, real64) + 1e-9_real64
            var_r = sum((rewards-mean_r)**2)/real(N_MAX, real64)
            p_grad = var_r / mean_r
            if (mod(s, 30) == 0) then
                write(LOG_UNIT, '(I5, " | ", I2, "/", I2, "/", I2, " | ", F10.4, " | ", F10.5)') &
                    s, a_count, n_count, s_count, mean_r, p_grad
                write(*, '(I5, " | ", I2, "/", I2, "/", I2, " | ", F10.4, " | ", F10.5)') &
                    s, a_count, n_count, s_count, mean_r, p_grad
            end if
            call world_step_n(.true.)
        end do
        
        write(LOG_UNIT, *) "[Final Hierarchy Status (Sorted by Reward)]"
        write(*, *) "[Final Hierarchy Status (Sorted by Reward)]"
        call print_sorted_agents()
    end subroutine run_phase_E

    subroutine init_world_n(n)
        integer, intent(in) :: n
        integer :: i, j, k
        real(real64) :: angle, ratio, diff
        if (allocated(w%agents)) deallocate(w%agents)
        allocate(w%agents(n))
        w%resource_pos = 0.0_real64
        w%l_base = 0.4_real64
        do i = 1, n
            w%agents(i)%idx = i
            angle = 2.0_real64 * PI * (i-1) / n
            w%agents(i)%x = 0.0_real64
            w%agents(i)%x(1) = 2.0_real64 * cos(angle)
            w%agents(i)%x(2) = 2.0_real64 * sin(angle)
            w%agents(i)%name = "Agent"
            w%agents(i)%K = 0.0_real64
            do j = 1, DIM; w%agents(i)%K(j,j) = 1.0_real64; end do
            w%agents(i)%A_val = 0.0_real64
            w%agents(i)%C_vec = [1.0_real64, 1.0_real64, 0.0_real64]
            w%agents(i)%reward = 0.0_real64
            w%agents(i)%mode = "Neutral"
            w%agents(i)%hunger = 0.0_real64
            
            ! 性格勾配の初期化
            ratio = real(i-1, real64) / real(n-1, real64)
            if (ratio < 0.2_real64) then
                w%agents(i)%h_threshold = 0.2_real64
                w%agents(i)%t_threshold = 5.0_real64
                w%agents(i)%e_power = 0.01_real64
            else if (ratio < 0.5_real64) then
                w%agents(i)%h_threshold = 0.6_real64
                w%agents(i)%t_threshold = 1.2_real64
                w%agents(i)%e_power = 0.8_real64
            else
                w%agents(i)%h_threshold = 1.2_real64
                w%agents(i)%t_threshold = 0.6_real64
                w%agents(i)%e_power = 5.0_real64
            end if
            
            ! 第16要素: 親和性の初期化 (環状コサイン)
            do j = 1, n
                diff = min(real(abs(i-j), real64), real(n-abs(i-j), real64))
                w%agents(i)%affinities(j) = cos(2.0_real64 * PI * diff / real(n, real64))
            end do
        end do
    end subroutine init_world_n

    subroutine world_step_n(enable_decide)
        logical, intent(in) :: enable_decide
        real(real64) :: v_list(DIM, size(w%agents))
        integer :: i
        do i = 1, size(w%agents); v_list(:,i) = get_agent_v_n(w%agents(i)); end do
        if (enable_decide) then; do i = 1, size(w%agents); call agent_decide_n(w%agents(i)); end do; end if
        do i = 1, size(w%agents); call agent_update_n(w%agents(i), v_list(:,i)); end do
    end subroutine world_step_n

    function get_agent_v_n(a) result(v_out)
        type(Agent), intent(in) :: a
        real(real64) :: v_out(DIM), v_pkgf(DIM), v_des(DIM), v_eth(DIM), eta(DIM), r_v, d_w, e_s, dist_sq, aff
        integer :: i, o
        v_pkgf = compute_co_diff_n(a)
        d_w = 0.3_real64 + a%hunger * 3.0_real64
        v_des = (w%resource_pos - a%x) * d_w
        v_eth = 0.0_real64
        
        do o = 1, size(w%agents)
            dist_sq = sum((a%x-w%agents(o)%x)**2)
            if (dist_sq < 1e-9) cycle
            
            ! 親和性に基づく力学の変調
            aff = a%affinities(w%agents(o)%idx)
            e_s = a%e_power * (1.5_real64 - aff)
            if (trim(a%mode) == "Aggressive") e_s = e_s * 0.01_real64
            if (trim(a%mode) == "Submissive") e_s = e_s * 2.0_real64
            
            v_eth = v_eth - e_s * (1.0_real64 / real(size(w%agents), real64)) * &
                    (1.0_real64 + a%C_vec(3)) / (dist_sq + 0.05_real64) * (a%x-w%agents(o)%x)
            
            ! 好きな相手への引力
            if (aff > 0.5_real64) v_eth = v_eth + 0.2_real64 * aff / (sqrt(dist_sq) + 1.0_real64) * (w%agents(o)%x-a%x)
        end do
        
        do i = 1, DIM; call random_number(r_v); eta(i) = (r_v*0.02_real64-0.01_real64); end do
        v_out = v_pkgf + v_des + w%l_base * v_eth + eta
    end function get_agent_v_n

    subroutine agent_decide_n(a)
        type(Agent), intent(inout) :: a
        real(real64) :: ten, hng, social_stress, dist
        integer :: o
        
        ! 社会的ストレスの計算
        social_stress = 0.0_real64
        do o = 1, size(w%agents)
            if (o == a%idx) cycle
            dist = sqrt(sum((a%x-w%agents(o)%x)**2)) + 1e-9_real64
            social_stress = social_stress - a%affinities(o) / (dist + 0.5_real64)
        end do
        
        ten = max(0.0_real64, a%C_vec(3) + social_stress * 0.2_real64)
        hng = a%hunger
        
        if (hng > a%h_threshold) then; a%mode = "Aggressive"
        else if (ten > a%t_threshold) then; a%mode = "Submissive"
        else; a%mode = "Neutral"; end if
        
        if (a%reward > 0.1_real64) a%hunger = a%hunger * 0.5_real64
    end subroutine agent_decide_n

    subroutine agent_update_n(a, v)
        type(Agent), intent(inout) :: a
        real(real64), intent(in) :: v(DIM)
        real(real64) :: d_p, d_c, ex, tau, r_v
        integer :: i
        d_p = sqrt(sum((a%x-w%resource_pos)**2))
        a%x = a%x + v * DT
        d_c = sqrt(sum((a%x-w%resource_pos)**2))
        call transport_K_n(a%K, a%x-v*DT, v)
        ex = 1.2_real64 * max(0.0_real64, (d_c-d_p)/DT) + 0.4_real64 * sqrt(sum(v**2))
        a%A_val = max(0.0_real64, min(5.0_real64, a%A_val + (-0.6_real64*a%A_val+ex)*DT))
        a%epsilon_K = 0.06_real64 * a%A_val
        do i=1,DIM; call random_number(r_v); a%K(i,i)=a%K(i,i)+(r_v*0.01_real64-0.005_real64)*a%A_val; end do
        tau = 0.35_real64
        a%C_vec(1) = a%C_vec(1) + (-tau*a%C_vec(1) + tanh(2.0_real64*a%C_vec(1)+1.0_real64/(1.0_real64+a%A_val))) * DT
        a%C_vec(2) = a%C_vec(2) + (-tau*a%C_vec(2) + tanh(2.0_real64*a%C_vec(2)+1.0_real64/(1.0_real64+a%epsilon_K))) * DT
        a%C_vec(3) = a%C_vec(3) + (-tau*a%C_vec(3) + tanh(a%A_val*1.3_real64)) * DT
        if (d_c < 0.4_real64) then; a%reward = a%reward + 0.4_real64/(1.0_real64+a%A_val)
        else; a%hunger = a%hunger + 0.15_real64*DT; end if
    end subroutine agent_update_n

    subroutine print_sorted_agents()
        type(Agent) :: temp
        integer :: i, j, n
        n = size(w%agents)
        do i = 1, n-1
            do j = i+1, n
                if (w%agents(i)%reward < w%agents(j)%reward) then
                    temp = w%agents(i); w%agents(i) = w%agents(j); w%agents(j) = temp
                end if
            end do
        end do
        do i = 1, n
            write(LOG_UNIT, '(A4, I2.2, ": Mode=", A10, ", Reward=", F8.4, ", Tension=", F6.3)') &
                "A_", w%agents(i)%idx, w%agents(i)%mode, w%agents(i)%reward, w%agents(i)%C_vec(3)
            write(*, '(A4, I2.2, ": Mode=", A10, ", Reward=", F8.4, ", Tension=", F6.3)') &
                "A_", w%agents(i)%idx, w%agents(i)%mode, w%agents(i)%reward, w%agents(i)%C_vec(3)
        end do
    end subroutine print_sorted_agents

    function compute_co_diff_n(a) result(v_out)
        type(Agent), intent(in) :: a
        real(real64) :: v_out(DIM), F_x(DIM,DIM), F_p(DIM,DIM), xp(DIM)
        integer :: i, j
        F_x = get_F_n(a%x)
        v_out = 0.0_real64
        do i = 1, DIM
            xp = a%x; xp(i) = xp(i) + EPSILON_MANIFOLD
            F_p = get_F_n(xp)
            do j = 1, DIM; v_out(j) = v_out(j) + (F_p(i,j)-F_x(i,j))/EPSILON_MANIFOLD; end do
        end do
    end function compute_co_diff_n

    function get_F_n(pos) result(F)
        real(real64), intent(in) :: pos(DIM)
        real(real64) :: F(DIM,DIM), om_x(DIM), om_p(DIM), pp(DIM)
        integer :: i, j
        om_x = get_om_n(pos)
        do i = 1, DIM
            pp = pos; pp(i) = pp(i) + 1e-4_real64; om_p = get_om_n(pp)
            do j = 1, DIM; F(i,j) = (om_p(j)-om_x(j))/1e-4_real64; end do
        end do
        F = F - transpose(F)
    end function get_F_n

    function get_om_n(pos) result(om)
        real(real64), intent(in) :: pos(DIM)
        real(real64) :: om(DIM), g(DIM,DIM)
        g = get_metric_n(pos); om = matmul(g, (w%resource_pos-pos)*0.4_real64)
    end function get_om_n

    function get_metric_n(x) result(g)
        real(real64), intent(in) :: x(DIM)
        real(real64) :: g(DIM,DIM), s(3)
        integer :: i
        g = 0.0_real64; s = [1.0_real64+0.5_real64*tanh(x(10)), 1.0_real64+0.5_real64*tanh(x(11)), 1.0_real64+0.5_real64*tanh(x(12))]
        do i = 1, DIM
            if (i <= 3) then; g(i,i) = s(1)
            else if (i <= 6) then; g(i,i) = s(2)
            else if (i <= 9) then; g(i,i) = s(3)
            else; g(i,i) = 1.0_real64; end if
        end do
    end function get_metric_n

    subroutine transport_K_n(K, x, v)
        real(real64), intent(inout) :: K(DIM,DIM)
        real(real64), intent(in) :: x(DIM), v(DIM)
        real(real64) :: Gam(DIM,DIM,DIM), Om(DIM,DIM), H(DIM,DIM)
        integer :: i_l, j_l, k_l
        call get_gam_n(x, Gam)
        Om = 0.0_real64
        do i_l = 1, DIM; do j_l = 1, DIM; do k_l = 1, DIM
            Om(i_l,j_l) = Om(i_l,j_l) + Gam(i_l,k_l,j_l) * v(k_l)
        end do; end do; end do
        H = exp_m_n(Om * DT); K = matmul(matmul(H, K), mat_i_n(H))
    end subroutine transport_K_n

    subroutine get_gam_n(x, G)
        real(real64), intent(in) :: x(DIM)
        real(real64), intent(out) :: G(DIM,DIM,DIM)
        real(real64) :: gi(DIM,DIM), pg(DIM,DIM,DIM), xp(DIM), xm(DIM)
        integer :: i, j, k, l
        gi = mat_i_n(get_metric_n(x))
        do k = 1, DIM
            xp = x; xp(k) = xp(k) + EPSILON_METRIC; xm = x; xm(k) = xm(k) - EPSILON_METRIC
            pg(k,:,:) = (get_metric_n(xp)-get_metric_n(xm))*(0.5_real64/EPSILON_METRIC)
        end do
        G = 0.0_real64
        do k = 1, DIM; do i = 1, DIM; do j = 1, DIM; do l = 1, DIM
            G(k,i,j) = G(k,i,j) + 0.5_real64*gi(k,l)*(pg(i,j,l)+pg(j,i,l)-pg(l,i,j))
        end do; end do; end do; end do
    end subroutine get_gam_n

    function mat_i_n(A) result(Ai)
        real(real64), intent(in) :: A(DIM,DIM)
        real(real64) :: Ai(DIM,DIM), m(DIM,2*DIM), p_v, f
        integer :: i, k
        Ai = 0.0_real64; do i=1,DIM; Ai(i,i)=1.0_real64; end do
        m(:,1:DIM) = A; m(:,DIM+1:2*DIM) = Ai
        do i = 1, DIM
            p_v = m(i,i); m(i,:) = m(i,:)/p_v
            do k = 1, DIM; if (i/=k) then; f = m(k,i); m(k,:) = m(k,:)-f*m(i,:); end if; end do
        end do
        Ai = m(:,DIM+1:2*DIM)
    end function mat_i_n

    function exp_m_n(A) result(E)
        real(real64), intent(in) :: A(DIM,DIM)
        real(real64) :: E(DIM,DIM), As(DIM,DIM), Ap(DIM,DIM), P(DIM,DIM), Q(DIM,DIM), n_inf
        real(real64) :: c(7) = [1.0, 0.5, 0.1, 0.01111111111111111, 0.0007575757575757576, 3.0303030303030303e-05, 5.050505050505051e-07]
        integer :: k_s, i
        n_inf = maxval(sum(abs(A), dim=2))
        k_s = max(0, int(ceiling(log(n_inf/0.5_real64)/log(2.0_real64))))
        As = A / (2.0_real64**k_s)
        P = 0.0; Q = 0.0; Ap = 0.0; do i=1,DIM; P(i,i)=1.0; Q(i,i)=1.0; Ap(i,i)=1.0; end do
        do i = 1, 6
            Ap = matmul(Ap, As); P = P + Ap * c(i+1)
            if (mod(i,2)==0) then; Q = Q + Ap * c(i+1); else; Q = Q - Ap * c(i+1); end if
        end do
        E = matmul(mat_i_n(Q), P)
        do i = 1, k_s; E = matmul(E, E); end do
    end function exp_m_n

end program emergence_sim_fortran_nbody
