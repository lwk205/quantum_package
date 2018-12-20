BEGIN_PROVIDER [ double precision, mo_coef_begin_iteration, (ao_num,mo_tot_num) ]
   implicit none
   BEGIN_DOC
   ! Void provider to store the coefficients of the |MO| basis at the beginning of the SCF iteration
   ! 
   ! Usefull to track some orbitals 
   END_DOC
END_PROVIDER

subroutine initialize_mo_coef_begin_iteration
 implicit none
 BEGIN_DOC
 ! 
 ! Initialize :c:data:`mo_coef_begin_iteration` to the current :c:data:`mo_coef`
 END_DOC
 mo_coef_begin_iteration = mo_coef
end

subroutine reorder_active_orb
 implicit none
 BEGIN_DOC 
! routines that takes the current :c:data:`mo_coef` and reorder the active orbitals (see :c:data:`list_act` and :c:data:`n_act_orb`) according to the overlap with :c:data:`mo_coef_begin_iteration`
 END_DOC
 integer :: i,j,iorb
 integer :: k,l
 double precision, allocatable :: accu(:)
 integer, allocatable :: index_active_orb(:),iorder(:)
 double precision, allocatable :: mo_coef_tmp(:,:)
 allocate(accu(mo_tot_num),index_active_orb(n_act_orb),iorder(mo_tot_num))
 allocate(mo_coef_tmp(ao_num,mo_tot_num))
 
 do i = 1, n_act_orb
  iorb = list_act(i)
  do j = 1, mo_tot_num
   accu(j) = 0.d0
   iorder(j) = j
   do k = 1, ao_num
    do l = 1, ao_num
     accu(j) += mo_coef_begin_iteration(k,iorb) * mo_coef(l,j) * ao_overlap(k,l)
    enddo
   enddo
   accu(j) = -dabs(accu(j))
  enddo
  call dsort(accu,iorder,mo_tot_num)
  index_active_orb(i) = iorder(1) 
 enddo

 double precision :: x
 integer :: i1,i2
 print*, 'swapping the active MOs'
 do j = 1, n_act_orb
  i1 = list_act(j)
  i2 = index_active_orb(j)
  print*, i1,i2
  do i=1,ao_num
    x = mo_coef(i,i1)
    mo_coef(i,i1) = mo_coef(i,i2)
    mo_coef(i,i2) = x
  enddo
 enddo
!call loc_cele_routine

 deallocate(accu,index_active_orb, iorder)
end
