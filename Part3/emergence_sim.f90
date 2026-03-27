program emergence_sim_fortran_dynamic
    use, intrinsic :: iso_fortran_env, only: real64, int32
    implicit none

    integer :: DIM, N_AGENTS
    real(real64), parameter :: EPSILON_METRIC = 1e-5
    real(real64), parameter :: EPSILON_MANIFOLD = 1e-4
    real(real64), parameter :: DT = 0.1_real64
    real(real64), parameter :: PI = 3.1415926535897932_real64

    type :: Agent
        integer :: idx
        real(real64), allocatable :: x(:)
        real(real64), allocatable :: K(:, :)
        real(real64) :: A_val, hunger, reward
        real(real64) :: C_vec(3)
        character(len=12) :: mode
        real(real64) :: h_threshold, t_threshold, e_power
        real(real64), allocatable :: affinities(:)
    end type Agent

    type :: World
        type(Agent), allocatable :: agents(:)
        real(real64), allocatable :: resource_pos(:)
        real(real64) :: l_base
    end type World

    type(World) :: w
    integer, parameter :: LOG_UNIT = 15
    character(len=256) :: log_dir = "/private/test/PKGF_Intelligence_Emergence/Part3/logs/fortran"

    call execute_part3_comparison()

contains

    subroutine execute_part3_comparison()
        integer :: n_list(3) = [4, 8, 16]
        integer :: i
        character(len=256) :: log_path
        
        do i = 1, 3
            N_AGENTS = n_list(i)
            DIM = n_list(i)
            write(*, '(A, I2, A, I2)') "--- Executing Case: N=", N_AGENTS, ", DIM=", DIM
            
            log_path = trim(log_dir) // "/case_N" // char(48 + N_AGENTS/10) // char(48 + mod(N_AGENTS,10)) // ".txt"
            open(unit=LOG_UNIT, file=trim(log_path), status='replace', action='write')
            call run_single_case()
            close(LOG_UNIT)
        end do
    end subroutine execute_part3_comparison

    subroutine run_single_case()
        integer :: s, j, a_count, n_count, s_count
        real(real64) :: avg_r, avg_t
        
        call init_world_dynamic(N_AGENTS, DIM)
        write(LOG_UNIT, '(A, I2, A, I2)') "--- Case: N=", N_AGENTS, ", DIM=", DIM
        write(LOG_UNIT, '(A)') "Step  | Modes (A/N/S)   | Avg_Rew    | Avg_Ten"
        
        do s = 0, 200
            a_count = 0; n_count = 0; s_count = 0
            avg_r = 0.0; avg_t = 0.0
            do j = 1, N_AGENTS
                if (trim(w%agents(j)%mode) == "Aggressive") a_count = a_count + 1
                if (trim(w%agents(j)%mode) == "Neutral") n_count = n_count + 1
                if (trim(w%agents(j)%mode) == "Submissive") s_count = s_count + 1
                avg_r = avg_r + w%agents(j)%reward
                avg_t = avg_t + w%agents(j)%C_vec(3)
            end do
            avg_r = avg_r / real(N_AGENTS, real64)
            avg_t = avg_t / real(N_AGENTS, real64)
            
            if (mod(s, 40) == 0) then
                write(LOG_UNIT, '(I5, " | ", I2, "/", I2, "/", I2, " | ", F10.4, " | ", F10.4)') &
                    s, a_count, n_count, s_count, avg_r, avg_t
                write(*, '(I5, " | ", I2, "/", I2, "/", I2, " | ", F10.4, " | ", F10.4)') &
                    s, a_count, n_count, s_count, avg_r, avg_t
            end if
            call world_step_dynamic()
        end do
    end subroutine run_single_case

    subroutine init_world_dynamic(n, d)
        integer, intent(in) :: n, d
        integer :: i, j, k
        real(real64) :: r_v, ratio, diff
        if (allocated(w%agents)) deallocate(w%agents)
        allocate(w%agents(n))
        if (allocated(w%resource_pos)) deallocate(w%resource_pos)
        allocate(w%resource_pos(d))
        w%resource_pos = 0.0
        w%l_base = 0.4
        
        do i = 1, n
            w%agents(i)%idx = i
            allocate(w%agents(i)%x(d))
            allocate(w%agents(i)%K(d, d))
            allocate(w%agents(i)%affinities(n))
            
            do k = 1, d
                call random_number(r_v)
                w%agents(i)%x(k) = (r_v - 0.5_real64) * 2.0_real64
            end do
            
            w%agents(i)%K = 0.0
            do j = 1, d; w%agents(i)%K(j,j) = 1.0; end do
            
            w%agents(i)%A_val = 0.0; w%agents(i)%hunger = 0.0; w%agents(i)%reward = 0.0
            w%agents(i)%C_vec = [1.0, 1.0, 0.0]; w%agents(i)%mode = "Neutral"
            
            ratio = real(i-1, real64) / real(n-1, real64)
            if (ratio < 0.2) then
                w%agents(i)%h_threshold = 0.2; w%agents(i)%t_threshold = 5.0; w%agents(i)%e_power = 0.01
            else if (ratio < 0.5) then
                w%agents(i)%h_threshold = 0.6; w%agents(i)%t_threshold = 1.2; w%agents(i)%e_power = 0.8
            else
                w%agents(i)%h_threshold = 1.2; w%agents(i)%t_threshold = 0.6; w%agents(i)%e_power = 5.0
            end if
            
            do j = 1, n
                diff = min(real(abs(i-j), real64), real(n-abs(i-j), real64))
                w%agents(i)%affinities(j) = cos(2.0_real64 * PI * diff / real(n, real64))
            end do
        end do
    end subroutine init_world_dynamic

    subroutine world_step_dynamic()
        real(real64), allocatable :: v_list(:,:)
        integer :: i
        allocate(v_list(DIM, N_AGENTS))
        do i = 1, N_AGENTS; v_list(:,i) = get_v_dynamic(w%agents(i)); end do
        do i = 1, N_AGENTS; call decide_dynamic(w%agents(i)); end do
        do i = 1, N_AGENTS; call update_dynamic(w%agents(i), v_list(:,i)); end do
        deallocate(v_list)
    end subroutine world_step_dynamic

    function get_v_dynamic(a) result(v_out)
        type(Agent), intent(in) :: a
        real(real64) :: v_out(DIM), v_pkgf(DIM), v_des(DIM), v_eth(DIM), eta(DIM), r_v, d_w, e_s, dist_sq, aff
        real(real64) :: om_x(DIM), om_p(DIM), pp(DIM)
        integer :: i, o
        
        ! Co-differential Approx
        om_x = get_om_dynamic(a%x)
        v_pkgf = 0.0
        do i = 1, DIM
            pp = a%x; pp(i) = pp(i) + 1e-4_real64; om_p = get_om_dynamic(pp)
            v_pkgf = v_pkgf + (om_p - om_x) / 1e-4_real64
        end do
        
        d_w = 0.3_real64 + a%hunger * 3.0_real64
        v_des = (w%resource_pos - a%x) * d_w
        
        v_eth = 0.0
        do o = 1, N_AGENTS
            dist_sq = sum((a%x-w%agents(o)%x)**2)
            if (dist_sq < 1e-9) cycle
            aff = a%affinities(o)
            e_s = a%e_power * (1.5_real64 - aff)
            if (trim(a%mode) == "Aggressive") e_s = e_s * 0.01
            if (trim(a%mode) == "Submissive") e_s = e_s * 2.0
            
            v_eth = v_eth - e_s * (2.0_real64 / real(N_AGENTS, real64)) * &
                    (1.0_real64 + a%C_vec(3)) / (dist_sq + 0.05_real64) * (a%x-w%agents(o)%x)
            if (aff > 0.5) v_eth = v_eth + 0.2_real64 * aff / (sqrt(dist_sq) + 1.0_real64) * (w%agents(o)%x-a%x)
        end do
        
        do i = 1, DIM; call random_number(r_v); eta(i) = (r_v*0.02-0.01); end do
        v_out = v_pkgf + v_des + w%l_base * v_eth + eta
    end function get_v_dynamic

    function get_om_dynamic(pos) result(om)
        real(real64), intent(in) :: pos(DIM)
        real(real64) :: om(DIM), g(DIM, DIM)
        g = get_metric_dynamic(pos); om = matmul(g, (w%resource_pos - pos) * 0.4_real64)
    end function get_om_dynamic

    function get_metric_dynamic(x) result(g)
        real(real64), intent(in) :: x(DIM)
        real(real64) :: g(DIM, DIM), s_ctx, avg_s
        integer :: i, ctx_idx
        g = 0.0; ctx_idx = (DIM * 3) / 4 + 1
        avg_s = 1.0
        if (ctx_idx <= DIM) then
            s_ctx = 0.0
            do i = ctx_idx, DIM; s_ctx = s_ctx + (1.0_real64 + 0.5_real64 * tanh(x(i))); end do
            avg_s = s_ctx / real(DIM - ctx_idx + 1, real64)
        end if
        do i = 1, DIM
            if (i < ctx_idx) then; g(i,i) = avg_s; else; g(i,i) = 1.0; end if
        end do
    end function get_metric_dynamic

    subroutine decide_dynamic(a)
        type(Agent), intent(inout) :: a
        real(real64) :: stress, dist
        integer :: o
        stress = 0.0
        do o = 1, N_AGENTS
            if (o == a%idx) cycle
            dist = sqrt(sum((a%x-w%agents(o)%x)**2)) + 1e-9
            stress = stress - a%affinities(o) / (dist + 0.5_real64)
        end do
        a%C_vec(3) = max(0.0_real64, min(2.0_real64, a%C_vec(3) + stress * 0.02)) ! Temporal tension shift
        
        if (a%hunger > a%h_threshold) then; a%mode = "Aggressive"
        else if (a%C_vec(3) > a%t_threshold) then; a%mode = "Submissive"
        else; a%mode = "Neutral"; end if
        if (a%reward > 0.1) a%hunger = a%hunger * 0.5
    end subroutine decide_dynamic

    subroutine update_dynamic(a, v)
        type(Agent), intent(inout) :: a
        real(real64), intent(in) :: v(DIM)
        real(real64) :: d_p, d_c, ex, tau, r_v
        integer :: i
        d_p = sqrt(sum((a%x - w%resource_pos)**2))
        a%x = a%x + v * DT
        d_c = sqrt(sum((a%x - w%resource_pos)**2))
        
        call transport_K_dynamic(a%K, a%x - v*DT, v)
        
        ex = 1.2_real64 * max(0.0_real64, (d_c-d_p)/DT) + 0.4_real64 * sqrt(sum(v**2))
        a%A_val = max(0.0_real64, min(5.0_real64, a%A_val + (-0.6_real64*a%A_val+ex)*DT))
        do i = 1, DIM; call random_number(r_v); a%K(i,i) = a%K(i,i) + (r_v*0.01-0.005)*a%A_val; end do
        
        tau = 0.35_real64
        a%C_vec(3) = a%C_vec(3) + (-tau*a%C_vec(3) + tanh(a%A_val*1.3_real64)) * DT
        a%C_vec(3) = max(0.0_real64, min(2.0_real64, a%C_vec(3)))
        
        if (d_c < 0.4) then; a%reward = a%reward + 0.4/(1.0+a%A_val)
        else; a%hunger = a%hunger + 0.15*DT; end if
    end subroutine update_dynamic

    subroutine transport_K_dynamic(K, x, v)
        real(real64), intent(inout) :: K(:, :)
        real(real64), intent(in) :: x(:), v(:)
        real(real64), allocatable :: Gam(:, :, :), Om(:, :), H(:, :)
        integer :: i_t, j_t, k_t, n_t
        n_t = size(x)
        allocate(Gam(n_t, n_t, n_t), Om(n_t, n_t), H(n_t, n_t))
        call get_gam_dynamic(x, Gam)
        Om = 0.0
        do i_t = 1, n_t; do j_t = 1, n_t; do k_t = 1, n_t
            Om(i_t, j_t) = Om(i_t, j_t) + Gam(i_t, k_t, j_t) * v(k_t)
        end do; end do; end do
        H = exp_m_dynamic(Om * DT)
        K = matmul(matmul(H, K), mat_i_dynamic(H))
        deallocate(Gam, Om, H)
    end subroutine transport_K_dynamic

    subroutine get_gam_dynamic(x, G)
        real(real64), intent(in) :: x(:)
        real(real64), intent(out) :: G(:, :, :)
        real(real64), allocatable :: gi(:, :), pg(:, :, :), xp(:), xm(:)
        integer :: i_g, j_g, k_g, l_g, n_g
        n_g = size(x)
        allocate(gi(n_g, n_g), pg(n_g, n_g, n_g), xp(n_g), xm(n_g))
        gi = mat_i_dynamic(get_metric_dynamic(x))
        do k_g = 1, n_g
            xp = x; xp(k_g) = xp(k_g) + EPSILON_METRIC
            xm = x; xm(k_g) = xm(k_g) - EPSILON_METRIC
            pg(k_g, :, :) = (get_metric_dynamic(xp) - get_metric_dynamic(xm)) * (0.5_real64 / EPSILON_METRIC)
        end do
        G = 0.0
        do k_g = 1, n_g; do i_g = 1, n_g; do j_g = 1, n_g; do l_g = 1, n_g
            G(k_g, i_g, j_g) = G(k_g, i_g, j_g) + 0.5_real64 * gi(k_g, l_g) * (pg(i_g, j_g, l_g) + pg(j_g, i_g, l_g) - pg(l_g, i_g, j_g))
        end do; end do; end do; end do
        deallocate(gi, pg, xp, xm)
    end subroutine get_gam_dynamic

    function mat_i_dynamic(A) result(Ai)
        real(real64), intent(in) :: A(:, :)
        real(real64) :: Ai(size(A,1), size(A,1)), m(size(A,1), 2*size(A,1)), p_v, f
        integer :: i, k, n
        n = size(A, 1)
        Ai = 0.0; do i = 1, n; Ai(i, i) = 1.0; end do
        m(:, 1:n) = A; m(:, n+1:2*n) = Ai
        do i = 1, n
            p_v = m(i, i); m(i, :) = m(i, :) / p_v
            do k = 1, n; if (i /= k) then; f = m(k, i); m(k, :) = m(k, :) - f * m(i, :); end if; end do
        end do
        Ai = m(:, n+1:2*n)
    end function mat_i_dynamic

    function exp_m_dynamic(A) result(E)
        real(real64), intent(in) :: A(:, :)
        real(real64) :: E(size(A,1), size(A,1)), As(size(A,1), size(A,1)), Ap(size(A,1), size(A,1))
        real(real64) :: P(size(A,1), size(A,1)), Q(size(A,1), size(A,1)), n_inf
        real(real64) :: c(7) = [1.0, 0.5, 0.1, 0.01111111111111111, 0.0007575757575757576, 3.0303030303030303e-05, 5.050505050505051e-07]
        integer :: k_s, i, n
        n = size(A, 1)
        n_inf = maxval(sum(abs(A), dim=2))
        k_s = max(0, int(ceiling(log(n_inf / 0.5_real64) / log(2.0_real64))))
        As = A / (2.0_real64**k_s)
        P = 0.0; Q = 0.0; Ap = 0.0; do i = 1, n; P(i, i) = 1.0; Q(i, i) = 1.0; Ap(i, i) = 1.0; end do
        do i = 1, 6
            Ap = matmul(Ap, As); P = P + Ap * c(i + 1)
            if (mod(i, 2) == 0) then; Q = Q + Ap * c(i + 1); else; Q = Q - Ap * c(i + 1); end if
        end do
        E = matmul(mat_i_dynamic(Q), P)
        do i = 1, k_s; E = matmul(E, E); end do
    end function exp_m_dynamic

    subroutine print_sorted_agents()
        ! 省略（必要に応じて実装）
    end subroutine print_sorted_agents

end program emergence_sim_fortran_dynamic
