subroutine save_erf_bi_elec_integrals_ao
 implicit none
 integer :: i,j,k,l
 PROVIDE ao_bielec_integrals_erf_in_map
 call ezfio_set_work_empty(.False.)
 call map_save_to_disk(trim(ezfio_filename)//'/work/ao_ints_erf',ao_integrals_erf_map)
 call ezfio_set_integrals_bielec_disk_access_ao_integrals("Read")
end

subroutine save_erf_bielec_ints_ao_into_ints_ao
 implicit none
 integer :: i,j,k,l
 PROVIDE ao_bielec_integrals_erf_in_map
 call ezfio_set_work_empty(.False.)
 call map_save_to_disk(trim(ezfio_filename)//'/work/ao_ints',ao_integrals_erf_map)
 call ezfio_set_integrals_bielec_disk_access_ao_integrals("Read")
end

