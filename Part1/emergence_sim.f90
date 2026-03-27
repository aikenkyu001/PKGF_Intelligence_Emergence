program emergence_sim_fortran
    use, intrinsic :: iso_fortran_env, only: real64, int32
    implicit none

    integer, parameter :: DIM = 12
    real(real64), parameter :: EPSILON_METRIC = 1e-5
    real(real64), parameter :: EPSILON_MANIFOLD = 1e-4
    real(real64), parameter :: DT = 0.1_real64

    type :: Agent
        character(len=10) :: name
        real(real64) :: x(DIM)
        real(real64) :: K(DIM, DIM)
        real(real64) :: A_val, epsilon_K, hunger
        real(real64) :: C_vec(3)
        real(real64) :: reward
        character(len=12) :: mode
    end type Agent

    type :: World
        type(Agent), allocatable :: agents(:)
        real(real64) :: resource_pos(DIM)
        real(real64) :: l_base
    end type World

    type(World) :: w
    integer :: s_main
    character(len=256) :: log_path
    integer, parameter :: LOG_UNIT = 15

    call execute_phases()

contains

    subroutine execute_phases()
        character(len=256) :: log_dir = "/private/test/PKGF_Intelligence_Emergence/logs/fortran"
        log_path = trim(log_dir) // "/phase_A_stability.txt"
        open(unit=LOG_UNIT, file=trim(log_path), status='replace', action='write')
        call run_phase_A()
        close(LOG_UNIT)
        log_path = trim(log_dir) // "/phase_B_deadlock.txt"
        open(unit=LOG_UNIT, file=trim(log_path), status='replace', action='write')
        call run_phase_B()
        close(LOG_UNIT)
        log_path = trim(log_dir) // "/phase_C_emergence.txt"
        open(unit=LOG_UNIT, file=trim(log_path), status='replace', action='write')
        call run_phase_C()
        close(LOG_UNIT)
    end subroutine execute_phases

    subroutine run_phase_A()
        integer :: s
        write(LOG_UNIT, *) "=== Phase A: Basic Stability (Single Agent) ==="
        write(*, *) "=== Phase A: Basic Stability (Single Agent) ==="
        call init_world(1)
        w%agents(1)%x(1) = 1.0_real64
        do s = 0, 50
            if (mod(s, 10) == 0) then
                write(LOG_UNIT, '(I5, " | ", F10.5, " | ", F10.5, " | ", F10.5)') s, w%agents(1)%x(1), calculate_det(w%agents(1)%K), w%agents(1)%reward
                write(*, '(I5, " | ", F10.5, " | ", F10.5, " | ", F10.5)') s, w%agents(1)%x(1), calculate_det(w%agents(1)%K), w%agents(1)%reward
            end if
            call world_step(.false.)
        end do
    end subroutine run_phase_A

    subroutine run_phase_B()
        integer :: s
        write(LOG_UNIT, *) "=== Phase B: Social Deadlock (Symmetric) ==="
        write(*, *) "=== Phase B: Social Deadlock (Symmetric) ==="
        call init_world(2)
        w%agents(1)%x(1) = 0.8_real64
        w%agents(2)%x(1) = -0.8_real64
        do s = 0, 50
            if (mod(s, 10) == 0) then
                write(LOG_UNIT, '(I5, " | ", F10.5, " | ", F10.5, " | ", F10.5)') s, w%agents(1)%x(1), w%agents(2)%x(1), sqrt(sum((w%agents(1)%x-w%agents(2)%x)**2))
                write(*, '(I5, " | ", F10.5, " | ", F10.5, " | ", F10.5)') s, w%agents(1)%x(1), w%agents(2)%x(1), sqrt(sum((w%agents(1)%x-w%agents(2)%x)**2))
            end if
            call world_step(.false.) 
        end do
    end subroutine run_phase_B

    subroutine run_phase_C()
        integer :: s
        write(LOG_UNIT, *) "=== Phase C: Strategic Emergence (Intelligence) ==="
        write(*, *) "=== Phase C: Strategic Emergence (Intelligence) ==="
        call init_world(2)
        w%agents(1)%x(1) = 0.8_real64
        w%agents(2)%x(1) = -0.8_real64
        do s = 0, 150
            if (mod(s, 15) == 0) then
                write(LOG_UNIT, '(I5, " | ", A10, " | ", A10, " | ", F10.4, " | ", F10.4, " | ", F6.3)') &
                    s, w%agents(1)%mode, w%agents(2)%mode, w%agents(1)%reward, w%agents(2)%reward, w%agents(1)%C_vec(3)
                write(*, '(I5, " | ", A10, " | ", A10, " | ", F10.4, " | ", F10.4, " | ", F6.3)') &
                    s, w%agents(1)%mode, w%agents(2)%mode, w%agents(1)%reward, w%agents(2)%reward, w%agents(1)%C_vec(3)
            end if
            call world_step(.true.)
        end do
    end subroutine run_phase_C

    subroutine init_world(n)
        integer, intent(in) :: n
        integer :: i, j
        if (allocated(w%agents)) deallocate(w%agents)
        allocate(w%agents(n))
        w%resource_pos = 0.0_real64
        w%l_base = 0.25_real64
        do i = 1, n
            w%agents(i)%x = 0.0_real64
            w%agents(i)%K = 0.0_real64
            do j = 1, DIM; w%agents(i)%K(j,j) = 1.0_real64; end do
            w%agents(i)%A_val = 0.0_real64
            w%agents(i)%C_vec = [1.0_real64, 1.0_real64, 0.0_real64]
            w%agents(i)%reward = 0.0_real64
            w%agents(i)%mode = "Neutral"
            w%agents(i)%hunger = 0.0_real64
        end do
    end subroutine init_world

    subroutine world_step(enable_decide)
        logical, intent(in) :: enable_decide
        real(real64) :: v_list(DIM, size(w%agents))
        integer :: i
        do i = 1, size(w%agents); v_list(:,i) = get_agent_v(w%agents(i)); end do
        if (enable_decide) then; do i = 1, size(w%agents); call agent_decide(w%agents(i)); end do; end if
        do i = 1, size(w%agents); call agent_update(w%agents(i), v_list(:,i)); end do
    end subroutine world_step

    function get_agent_v(a) result(v_out)
        type(Agent), intent(in) :: a
        real(real64) :: v_out(DIM), v_pkgf(DIM), v_des(DIM), v_eth(DIM), eta(DIM), r_v, d_w, e_s, dist_sq
        integer :: i, o
        v_pkgf = compute_co_diff(a)
        d_w = 0.5_real64 + a%hunger * 1.5_real64
        v_des = (w%resource_pos - a%x) * d_w
        v_eth = 0.0_real64; e_s = 1.0_real64
        if (trim(a%mode) == "Aggressive") e_s = 0.05_real64
        if (trim(a%mode) == "Submissive") e_s = 3.0_real64
        do o = 1, size(w%agents)
            if (abs(a%x(1)-w%agents(o)%x(1))<1e-12) cycle
            dist_sq = sum((a%x-w%agents(o)%x)**2)
            v_eth = v_eth - e_s * (1.2_real64 + a%C_vec(3)) / (dist_sq + 0.1_real64) * (a%x-w%agents(o)%x)
        end do
        do i = 1, DIM; call random_number(r_v); eta(i) = (r_v*0.04_real64-0.02_real64)*(1.0_real64+a%A_val); end do
        v_out = v_pkgf + v_des + w%l_base * v_eth + eta
    end function get_agent_v

    subroutine agent_decide(a)
        type(Agent), intent(inout) :: a
        character(len=12) :: other_m
        real(real64) :: p_agg, r_v
        integer :: o
        if (trim(a%mode) == "Neutral") then
            if (a%C_vec(3) > 1.0_real64 .or. a%hunger > 0.5_real64) then
                other_m = "Neutral"
                do o = 1, size(w%agents); if (abs(a%x(1)-w%agents(o)%x(1))>1e-9) other_m = w%agents(o)%mode; end do
                p_agg = 0.5_real64
                if (trim(other_m) == "Aggressive") p_agg = 0.1_real64
                if (trim(other_m) == "Submissive") p_agg = 0.9_real64
                call random_number(r_v)
                if (r_v < p_agg) then; a%mode = "Aggressive"; else; a%mode = "Submissive"; end if
            end if
        end if
        if (a%reward > 0.5_real64) a%hunger = a%hunger * 0.5_real64
    end subroutine agent_decide

    subroutine agent_update(a, v)
        type(Agent), intent(inout) :: a
        real(real64), intent(in) :: v(DIM)
        real(real64) :: d_p, d_c, ex, tau, r_v
        integer :: i
        d_p = sqrt(sum((a%x-w%resource_pos)**2))
        a%x = a%x + v * DT
        d_c = sqrt(sum((a%x-w%resource_pos)**2))
        call transport_K(a%K, a%x-v*DT, v)
        ex = 1.2_real64 * max(0.0_real64, (d_c-d_p)/DT) + 0.3_real64 * sqrt(sum(v**2))
        a%A_val = max(0.0_real64, min(5.0_real64, a%A_val + (-0.5_real64*a%A_val+ex)*DT))
        a%epsilon_K = 0.05_real64 * a%A_val
        do i=1,DIM; call random_number(r_v); a%K(i,i)=a%K(i,i)+(r_v*0.01_real64-0.005_real64)*a%A_val; end do
        tau = 0.3_real64
        a%C_vec(1) = a%C_vec(1) + (-tau*a%C_vec(1) + tanh(2.0_real64*a%C_vec(1)+1.0_real64/(1.0_real64+a%A_val))) * DT
        a%C_vec(2) = a%C_vec(2) + (-tau*a%C_vec(2) + tanh(2.0_real64*a%C_vec(2)+1.0_real64/(1.0_real64+a%epsilon_K))) * DT
        a%C_vec(3) = a%C_vec(3) + (-tau*a%C_vec(3) + tanh(a%A_val*1.2_real64)) * DT
        if (d_c < 0.4_real64) then; a%reward = a%reward + 0.3_real64/(1.0_real64+a%A_val)
        else; a%hunger = a%hunger + 0.1_real64*DT; end if
    end subroutine agent_update

    function compute_co_diff(a) result(v_out)
        type(Agent), intent(in) :: a
        real(real64) :: v_out(DIM), F_x(DIM,DIM), F_p(DIM,DIM), xp(DIM)
        integer :: i, j
        F_x = get_F(a%x)
        v_out = 0.0_real64
        do i = 1, DIM
            xp = a%x; xp(i) = xp(i) + EPSILON_MANIFOLD
            F_p = get_F(xp)
            do j = 1, DIM; v_out(j) = v_out(j) + (F_p(i,j)-F_x(i,j))/EPSILON_MANIFOLD; end do
        end do
    end function compute_co_diff

    function get_F(pos) result(F)
        real(real64), intent(in) :: pos(DIM)
        real(real64) :: F(DIM,DIM), om_x(DIM), om_p(DIM), pp(DIM)
        integer :: i, j
        om_x = get_om(pos)
        do i = 1, DIM
            pp = pos; pp(i) = pp(i) + 1e-4_real64; om_p = get_om(pp)
            do j = 1, DIM; F(i,j) = (om_p(j)-om_x(j))/1e-4_real64; end do
        end do
        F = F - transpose(F)
    end function get_F

    function get_om(pos) result(om)
        real(real64), intent(in) :: pos(DIM)
        real(real64) :: om(DIM), g(DIM,DIM)
        g = get_metric(pos); om = matmul(g, (w%resource_pos-pos)*0.5_real64)
    end function get_om

    function get_metric(x) result(g)
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
    end function get_metric

    subroutine transport_K(K, x, v)
        real(real64), intent(inout) :: K(DIM,DIM)
        real(real64), intent(in) :: x(DIM), v(DIM)
        real(real64) :: Gam(DIM,DIM,DIM), Om(DIM,DIM), H(DIM,DIM)
        integer :: i_l, j_l, k_l
        call get_gam(x, Gam)
        Om = 0.0_real64
        do i_l = 1, DIM; do j_l = 1, DIM; do k_l = 1, DIM
            Om(i_l,j_l) = Om(i_l,j_l) + Gam(i_l,k_l,j_l) * v(k_l)
        end do; end do; end do
        H = exp_m(Om * DT); K = matmul(matmul(H, K), mat_i(H))
    end subroutine transport_K

    subroutine get_gam(x, G)
        real(real64), intent(in) :: x(DIM)
        real(real64), intent(out) :: G(DIM,DIM,DIM)
        real(real64) :: gi(DIM,DIM), pg(DIM,DIM,DIM), xp(DIM), xm(DIM)
        integer :: i, j, k, l
        gi = mat_i(get_metric(x))
        do k = 1, DIM
            xp = x; xp(k) = xp(k) + EPSILON_METRIC; xm = x; xm(k) = xm(k) - EPSILON_METRIC
            pg(k,:,:) = (get_metric(xp)-get_metric(xm))*(0.5_real64/EPSILON_METRIC)
        end do
        G = 0.0_real64
        do k = 1, DIM; do i = 1, DIM; do j = 1, DIM; do l = 1, DIM
            G(k,i,j) = G(k,i,j) + 0.5_real64*gi(k,l)*(pg(i,j,l)+pg(j,i,l)-pg(l,i,j))
        end do; end do; end do; end do
    end subroutine get_gam

    function calculate_det(A) result(det)
        real(real64), intent(in) :: A(DIM,DIM)
        real(real64) :: det, lu(DIM,DIM), p_v, f
        integer :: i, k
        lu = A; det = 1.0_real64
        do i = 1, DIM
            p_v = lu(i,i)
            if (abs(p_v) < 1e-15) then
                do k = i+1, DIM
                    if (abs(lu(k,i)) > abs(p_v)) then
                        lu([i,k], :) = lu([k,i], :); det = -det; p_v = lu(i,i); exit
                    end if
                end do
            end if
            det = det * p_v
            do k = i+1, DIM; f = lu(k,i)/p_v; lu(k,i) = f; lu(k,i+1:DIM) = lu(k,i+1:DIM)-f*lu(i,i+1:DIM); end do
        end do
    end function calculate_det

    function mat_i(A) result(Ai)
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
    end function mat_i

    function exp_m(A) result(E)
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
        E = matmul(mat_i(Q), P)
        do i = 1, k_s; E = matmul(E, E); end do
    end function exp_m

end program emergence_sim_fortran
