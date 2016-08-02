program fci_zmq
  implicit none
  integer                        :: i,k
  logical, external :: detEq
  
  double precision, allocatable  :: pt2(:), norm_pert(:), H_pert_diag(:)
  integer                        :: N_st, degree
  integer(bit_kind) :: chk
  N_st = N_states
  allocate (pt2(N_st), norm_pert(N_st),H_pert_diag(N_st))
  
  pt2 = 1.d0
  diag_algorithm = "Lapack"
  
  if (N_det > N_det_max) then
    call diagonalize_CI
    call save_wavefunction
    psi_det = psi_det_sorted
    psi_coef = psi_coef_sorted
    N_det = N_det_max
    soft_touch N_det psi_det psi_coef
    call diagonalize_CI
    call save_wavefunction
    print *,  'N_det    = ', N_det
    print *,  'N_states = ', N_states
    print *,  'PT2      = ', pt2
    print *,  'E        = ', CI_energy
    print *,  'E+PT2    = ', CI_energy+pt2
    print *,  '-----'
  endif
  double precision :: i_H_psi_array(N_states),diag_H_mat_elem,h,i_O1_psi_array(N_states)
  double precision :: E_CI_before(N_states)
  

  integer :: n_det_before
  print*,'Beginning the selection ...'
  E_CI_before = CI_energy
  
  do while (N_det < N_det_max.and.maxval(abs(pt2(1:N_st))) > pt2_max)
    n_det_before = N_det
    ! call H_apply_FCI(pt2, norm_pert, H_pert_diag,  N_st)
    call ZMQ_selection(max(1024-N_det, N_det), pt2)
    
    PROVIDE  psi_coef
    PROVIDE  psi_det
    PROVIDE  psi_det_sorted

    if (N_det > N_det_max) then
       psi_det = psi_det_sorted
       psi_coef = psi_coef_sorted
       N_det = N_det_max
       soft_touch N_det psi_det psi_coef
    endif
    call diagonalize_CI
    call save_wavefunction
  ! chk = 0_8
  ! do i=1, N_det
  ! do k=1, N_int
  !   chk = xor(psi_det(k,1,i), chk)
  !   chk = xor(psi_det(k,2,i), chk)
  ! end do
  ! end do
  ! print *, "CHK ", chk

    print *,  'N_det          = ', N_det
    print *,  'N_states       = ', N_states
    do  k = 1, N_states
    print*,'State ',k
    print *,  'PT2            = ', pt2(k)
    print *,  'E              = ', CI_energy(k)
    print *,  'E(before)+PT2  = ', E_CI_before(k)+pt2(k)
    enddo
    print *,  '-----'
    E_CI_before = CI_energy
    if(N_states.gt.1)then
     print*,'Variational Energy difference'
     do i = 2, N_states
      print*,'Delta E = ',CI_energy(i) - CI_energy(1)
     enddo
    endif
    if(N_states.gt.1)then
     print*,'Variational + perturbative Energy difference'
     do i = 2, N_states
      print*,'Delta E = ',E_CI_before(i)+ pt2(i) - (E_CI_before(1) + pt2(1))
     enddo
    endif
    E_CI_before = CI_energy
    call ezfio_set_full_ci_energy(CI_energy)
  enddo
   N_det = min(N_det_max,N_det)
   touch N_det psi_det psi_coef
   call diagonalize_CI
!    if(do_pt2_end)then
!     print*,'Last iteration only to compute the PT2'
!     threshold_selectors = 1.d0
!     threshold_generators = 0.999d0
!     call H_apply_FCI_PT2(pt2, norm_pert, H_pert_diag,  N_st)
!  
!     print *,  'Final step'
!     print *,  'N_det    = ', N_det
!     print *,  'N_states = ', N_states
!     print *,  'PT2      = ', pt2
!     print *,  'E        = ', CI_energy
!     print *,  'E+PT2    = ', CI_energy+pt2
!     print *,  '-----'
!     call ezfio_set_full_ci_energy_pt2(CI_energy+pt2)
!    endif
   call save_wavefunction
end




subroutine ZMQ_selection(N, pt2)
  use f77_zmq
  use selection_types
  
  implicit none
  
  character*(512)                :: task 
  integer(ZMQ_PTR)               :: zmq_to_qp_run_socket 
  integer, intent(in)            :: N
  type(selection_buffer)         :: b
  integer                        :: i
  integer, external              :: omp_get_thread_num
  double precision, intent(out)  :: pt2(N_states)
  
  
  provide nproc
  provide ci_electronic_energy
  call new_parallel_job(zmq_to_qp_run_socket,"selection")
  call zmq_put_psi(zmq_to_qp_run_socket,1,ci_electronic_energy,size(ci_electronic_energy))
  call zmq_set_running(zmq_to_qp_run_socket)
  call create_selection_buffer(N, N*2, b)
  do i= N_det_generators, 1, -1
    write(task,*) i, N
    call add_task_to_taskserver(zmq_to_qp_run_socket,task)
  end do

    !$OMP PARALLEL DEFAULT(none)  SHARED(b, pt2)  PRIVATE(i) NUM_THREADS(nproc+1) shared(ci_electronic_energy_is_built, n_det_generators_is_built, n_states_is_built, n_int_is_built, nproc_is_built)
      i = omp_get_thread_num()
      if (i==0) then
        call selection_collector(b, pt2)
      else
        call selection_dressing_slave_inproc(i)
      endif
  !$OMP END PARALLEL
  call end_parallel_job(zmq_to_qp_run_socket, 'selection') 
  call fill_H_apply_buffer_no_selection(b%cur,b%det,N_int,0) !!! PAS DE ROBIN
  call copy_H_apply_buffer_to_wf()
end subroutine


subroutine selection_dressing_slave_inproc(i)
  implicit none
  integer, intent(in)            :: i

  call selection_slaved(1,i,ci_electronic_energy)
end
