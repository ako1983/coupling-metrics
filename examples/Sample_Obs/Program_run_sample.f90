!---------------------------------------------------------------------------------------------
!
!  Purpose:  This program runs a quick sample data test against several observed profiles from 
!            the Intensive Observation Period on June 6th, 2002 from the Southern Great Plains
!            Atmosphere Radiation Radiation Central Facility. 
!            **** NOTE --  This is NOT a generic program but specific to this input file structure
!
!

Program Coupling_metrics

       use RH_Tend_Mod
       use Mixing_Diag_Mod
       use HCF_vars_calc
       use Soil_Memory_Mod
       use Terrestrial_Coupling_Mod
       use Conv_Trig_Pot_Mod
       implicit none

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   
   ! PBL and surface flux routine declaractions ! 
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ! dimension sizes
   integer, parameter                        ::  nlev  =  23
   integer, parameter                        ::  ntim  =  8
   integer, parameter                        ::  nday  =  1

   ! Loop indices
   integer                                   ::  tt, zz

   ! file name prefix for each file that is looped over
   integer                                   ::  unit_profile , unit_fluxes

   ! Used for clocking cpu-time
   real(4)                                   ::  start, finish

   ! Input variables read in from file 
   real(4), dimension(ntim,nlev)             ::  tlev, plev, hlev, qlev
   real(4), dimension(ntim,1)                ::  t2m , p2m , h2m , q2m
   real(4), dimension(ntim,1)                ::  shf , lhf , pblh

   real(4), dimension(ntim)                  :: tbm    ,  bclh   , bclp ,  tdef,    &
                                                hadv   ,  tranp  , tadv ,           &
                                                shdef  ,  lhdef  , eadv
   real(4), dimension(ntim,1)                :: sh_ent, lh_ent, sh_sfc, lh_sfc, sh_tot,  lh_tot
   real(4), dimension(ntim,1)                :: lcl_deficit
   real(4), dimension(nday,1)                :: evapf

   real(4), dimension(ntim,1)                :: A_SH, A_LH
   real(4), dimension(ntim)                  :: ef, ne, heating, growth, dry, drh_dt

   real(4)                                   :: yr1, mn1, hr1
   real(4)                                   :: yr2, mn2, hr2
   real(4)                                   :: yr3, mn3, hr3
   real(4)                                   :: yr4, mn4, hr4
   real(4)                                   :: yr5, mn5, hr5
   real(4)                                   :: yr6, mn6, hr6
   real(4)                                   :: yr7, mn7, hr7

   ! missing value read in from file
   real(4), parameter                        ::  missing = -9999.

   ! Format statements
   character(len=24), parameter :: FMT1 = "(6(F12.4,2x))"   
   character(len=24), parameter :: FMT2 = "(4(A,2x))"   

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   
   ! Convective Triggering Potential declarations    ! 
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   integer, parameter                 ::  nlev_ctp  = 23
   real(4), dimension(ntim)           ::  ctp, hilow
   real(4), dimension(ntim,nlev_ctp)  ::  t_ctp, q_ctp, p_ctp

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   
   ! Surface and soil moisture routine declaractions ! 
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   integer, parameter                        ::  nhr   =  2161
   integer, parameter                        ::  nyr   =  16
   real(4), parameter                        ::  miss  =  -99999.

   integer                                   ::  unit_soilm
   real(4), dimension(nyr)                   ::  soil_memory
   real(4), dimension(nyr,nhr)               ::  soil_in
   real(4), dimension(nhr,nyr)               ::  soil_moisture
   real(4), dimension(nhr,nyr)               ::  soil_memory_all


   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   
   ! Used for terrestrial Coupling Parameter ! 
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   integer, parameter                        ::  ntim1 =  1350

   integer                                   ::  unit_terra
   real(4), dimension(ntim1,1)               ::  soilm_terra
   real(4), dimension(ntim1,1)               ::  shf_terra
   real(4), dimension(ntim1,1)               ::  lhf_terra
   real(4), dimension(1)                     ::  tcp_shf, tcp_lhf

!---------------------------------------------------------------------------------

         !********************************  
         !***                               
         !***    Initialize inputs to missing values
         !***                               
         !********************************  
         plev           =  missing
         tlev           =  missing
         qlev           =  missing
         hlev           =  missing
         t2m            =  missing
         q2m            =  missing
         h2m            =  missing
         p2m            =  missing

         shf            =  missing
         lhf            =  missing
         pblh           =  missing

         tbm            =  missing
         tdef           =  missing
         shdef          =  missing
         bclp           =  missing
         bclh           =  missing
         lhdef          =  missing
         eadv           =  missing
         hadv           =  missing
         tranp          =  missing
         tadv           =  missing
         sh_ent         =  missing
         lh_ent         =  missing
         sh_sfc         =  missing
         lh_sfc         =  missing
         sh_tot         =  missing
         lh_tot         =  missing
         lcl_deficit    =  missing
         evapf          =  missing

         ef             =  missing
         ne             =  missing
         heating        =  missing
         growth         =  missing
         dry            =  missing
         drh_dt         =  missing

         soil_moisture  =  miss
         soil_memory    =  miss
 
         ctp            =  missing
         hilow          =  missing


         !*****************************************  
         !***                               
         !***    Read sample profile data for HCF
         !***                               
         !*****************************************
         unit_profile  =  10
         open( unit=unit_profile, file='Sample_profile.txt' )
         do zz=1,nlev
            read(unit_profile,*) yr1,mn1,hr1,plev(1,zz),hlev(1,zz),tlev(1,zz),qlev(1,zz),  &
                                 yr2,mn2,hr2,plev(2,zz),hlev(2,zz),tlev(2,zz),qlev(2,zz),  &
                                 yr3,mn3,hr3,plev(3,zz),hlev(3,zz),tlev(3,zz),qlev(3,zz),  &
                                 yr4,mn4,hr4,plev(4,zz),hlev(4,zz),tlev(4,zz),qlev(4,zz),  &
                                 yr5,mn5,hr5,plev(5,zz),hlev(5,zz),tlev(5,zz),qlev(5,zz),  &
                                 yr6,mn6,hr6,plev(6,zz),hlev(6,zz),tlev(6,zz),qlev(6,zz),  &
                                 yr7,mn7,hr7,plev(7,zz),hlev(7,zz),tlev(7,zz),qlev(7,zz)

         end do
         close(unit_profile)



         !********************************  
         !***                               
         !***    Read sample flux and surface data
         !***                               
         !********************************  
         unit_fluxes  =  11
         open( unit=unit_fluxes, file='Sample_fluxes.txt' )
         do tt=1,ntim-1
            read(unit_fluxes,*) p2m(tt,1),h2m(tt,1),t2m(tt,1),q2m(tt,1),shf(tt,1),lhf(tt,1),pblh(tt,1)
         end do
         close(unit_fluxes)
         where( p2m .ne.missing )  p2m  =  p2m  * 1e2
         where( pblh.ne.missing )  pblh =  pblh * 1e3



         !********************************  
         !***                               
         !***    Read sample soil moisture data
         !***                               
         !********************************  
         unit_soilm  =  12
         open ( unit=unit_soilm, file='Sample_soilm.txt' )
         read ( unit_soilm,*)    soil_in
         close( unit_soilm  )
         soil_moisture = transpose(soil_in)



         !*****************************************************************************
         !***                               
         !***    Read sample flux and soil moisture for Terrestrail Coupling Parameter
         !***                               
         !*****************************************************************************
         unit_terra  =  14
         open( unit=unit_terra, file='Sample_tcp.csv' )
         do tt=1,ntim1
            read(unit_terra,*) soilm_terra(tt,1), shf_terra(tt,1), lhf_terra(tt,1)
         end do
         close(unit_terra)


         !*****************************************  
         !***                               
         !***    Map data for CTP-HiLow Calculation
         !***                               
         !*****************************************
         p_ctp  =  plev
         q_ctp  =  qlev
         t_ctp  =  tlev



         !---------------------------------------------
         !---
         !--- Heated Condensation Section
         !---
         !---------------------------------------------
         !**********************************    
         !*** Loop over time
         !**********************************    
         call cpu_time(start)
         do tt = 1,ntim

                    call hcfcalc( nlev       ,  missing                            ,    &
                                  tlev (tt,:),  plev (tt,:), qlev(tt,:),  hlev(tt,:),    &
                                  t2m  (tt,1),  p2m  (tt,1), q2m (tt,1),  h2m (tt,1),    &
                                  tbm  (tt)  ,  bclh (tt)  , bclp(tt)  ,  tdef(tt)  ,    &
                                  hadv (tt)  ,  tranp(tt)  , tadv(tt)  ,                 &
                                  shdef(tt)  ,  lhdef(tt)  , eadv(tt)                    )


         end do
         call cpu_time(finish)
         print '("Heated Condensation Framework   =   ",f10.3," seconds.")',finish-start



         !---------------------------------------------
         !---
         !--- Mixing Diagrams Section
         !---
         !---------------------------------------------
         call cpu_time(start)
         call mixing_diag ( 1          , ntim       , ntim       ,                          &  
                            t2m (:,1:1), p2m(:,1:1) , q2m(:,1:1) ,                          &
                            pblh(:,1:1), shf(:,1:1) , lhf(:,1:1) ,  8.*3600.,               &
                            sh_ent     , lh_ent     ,                                       &
                            sh_sfc     , lh_sfc     , sh_tot     ,  lh_tot, evapf(1:1,1:1), &
                            lcl_deficit(:,1:1),  missing )
         call cpu_time(finish)
         print '("Mixing Diagrams   =   ",f10.3," seconds.")',finish-start


         !---------------------------------------------
         !---
         !--- Relative Humidity Tendency Section
         !---
         !---------------------------------------------
         call cpu_time(start)
         call rh_tend_calc ( nlev     ,  ntim   ,                          &
                             tlev     ,  qlev   ,  hlev   ,  plev    ,     &
                             pblh     ,  shf    ,  lhf    ,  8.*3600.,     &
                             ef       ,  ne     ,                          &
                             heating  ,  growth ,  dry    ,  drh_dt , missing  )

         call cpu_time(finish)
         print '("Relative Humidity Tendency   =   ",f10.3," seconds.")',finish-start


         !---------------------------------------------
         !---
         !--- Soil Moisture Memory Section
         !---
         !---------------------------------------------
         soil_memory_all  =  miss
         call cpu_time(start)
         call soilm_memory ( nyr,  nhr,  soil_moisture,  soil_memory_all(1,:),  miss )
         call cpu_time(finish)
         print '("Soil Moisture Memory   =   ",f10.3," seconds.")',finish-start



         !---------------------------------------------
         !---
         !--- Terrestrial Coupling Section
         !---
         !---------------------------------------------
         tcp_shf  =  miss
         tcp_lhf  =  miss
         call  cpu_time(start)
         call  terra_coupling( 1,  ntim1,  soilm_terra,  shf_terra, tcp_shf(1),  miss )
         call  terra_coupling( 1,  ntim1,  soilm_terra,  lhf_terra, tcp_lhf(1),  miss )
         call  cpu_time(finish)
         print '("Terrestrail Coupling Parameter   =   ",f10.3," seconds.")',finish-start



         !---------------------------------------------
         !---
         !--- Convective Triggering Potenitl - LL humidity
         !---
         !---------------------------------------------
         !**********************************    
         !*** Loop over time
         !**********************************    
         call cpu_time(start)
         do tt = 1,ntim

                    call ctp_hi_low( nlev_ctp ,  t_ctp(tt,:),  q_ctp(tt,:), p_ctp(tt,:), &
                                     t2m(tt,1),  q2m  (tt,1),  p2m  (tt,1), ctp  (tt)  , hilow(tt), missing )

         end do
         call cpu_time(finish)
         print '("Convective Triggering Potential   =   ",f10.3," seconds.")',finish-start





         !---------------------------------------------
         !---
         !--- Output for sanity check on each metric
         !--- 
         !---------------------------------------------
         write(*,*)
         write(*,*)
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!      Heated Condensation Output      !!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,FMT2) "       TDEF",    "        TBM","   BCL Height",    "  BCL Pressure"
         do tt=1,ntim-1
            write(*,FMT1)  tdef(tt), tbm(tt), bclh(tt)/1e3, bclp(tt)/1e2
         end do
         write(*,*)
         write(*,FMT2)  "       SHDEF","         LHDEF","    Energy Advantage","   Transition Pressure"
         do tt=1,ntim-1
            write(*,FMT1)  shdef(tt)/1e6, lhdef(tt)/1e6, eadv(tt), tranp(tt)/1e2
         end do
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)

         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!      Mixing Diagrams Output      !!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,FMT2) " SH Entrainment",    " SH Surface", "   SH Total",    "Entrainment Ratio"
         A_LH  =  missing
         A_SH  =  missing
         where( sh_ent.ne.missing .and. sh_sfc.ne.missing )   A_SH  =  sh_ent/sh_sfc
         where( lh_ent.ne.missing .and. lh_sfc.ne.missing )   A_LH  =  lh_ent/lh_sfc
         do tt=1,ntim-1
            write(*,FMT1)  sh_ent(tt,1), sh_sfc(tt,1), sh_tot(tt,1), A_SH(tt,1), lcl_deficit(tt,1), evapf
         end do
         write(*,*) 
         write(*,FMT2) " LH Entrainment",    " LH Surface", "   LH Total",    "Entrainment Ratio"
         do tt=1,ntim-1
             write(*,FMT1)  lh_ent(tt,1), lh_sfc(tt,1), lh_tot(tt,1), A_LH(tt,1)
         end do
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
         write(*,*)  "  !!!!!!!!!!!      RH Tendency Output      !!!!!!!!!!!!"
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
         write(*,FMT2) "       EF", "           NE", "      Estimate dRH/dt"
         do tt=1,ntim-1
            write(*,FMT1)  ef(tt), ne(tt), drh_dt(tt)
         end do
         write(*,*)
         write(*,FMT2)  "  PBL Drying","  PBL Heating","  PBL Growth"
         do tt=1,ntim-1
            write(*,FMT1)  dry(tt), heating(tt), growth(tt)
         end do
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)

         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!      Soil Moisture Memory Output      !!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,FMT2) "       Memory in days "
         do tt=1,nyr
            write(*,*)  tt, soil_memory_all(1,tt)/24
         end do
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!      Terrestrial Coupling Parameter     !!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,FMT2) "    Sensible and Latent heat coupling parameters against soil moisture "
         write(*,*)  tcp_shf, tcp_lhf
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!    Convective Triggering Potential   !!!!!!!!!!!!  "
         write(*,*)  "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  "
         write(*,FMT2) "       CTP",    "        Hi-Low"
         do tt=1,ntim
            write(*,FMT1)  ctp(tt), hilow(tt)
         end do
         write(*,*)
         write(*,*)
         write(*,*)



end Program Coupling_metrics
