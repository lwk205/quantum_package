subroutine huckel_guess
  implicit none
  BEGIN_DOC
! Build the MOs using the extended Huckel model
  END_DOC
  integer                        :: i,j
  double precision               :: accu
  double precision               :: c
  character*(64)                 :: label

  mo_coef = ao_ortho_lowdin_coef
  TOUCH mo_coef
  label = "Guess"
  call mo_as_eigvectors_of_mo_matrix(mo_mono_elec_integral,          &
                                     size(mo_mono_elec_integral,1),  &
                                     size(mo_mono_elec_integral,2),label)
  TOUCH mo_coef

  c = 0.5d0 * 1.75d0

  do j=1,ao_num
    !DIR$ VECTOR ALIGNED
    do i=1,ao_num
      Fock_matrix_ao(i,j) = c*ao_overlap(i,j)*(ao_mono_elec_integral_diag(i) + &
                                                 ao_mono_elec_integral_diag(j))
    enddo
    Fock_matrix_ao(j,j) = Fock_matrix_alpha_ao(j,j)
  enddo
  TOUCH Fock_matrix_ao
  print *,  "Huckel matrix computed"
  mo_coef = eigenvectors_fock_matrix_mo
  SOFT_TOUCH mo_coef
  print *,  "Saving MOs"
  call save_mos
  print *,  "Saving MOs saved"

end
