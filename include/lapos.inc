! -------------------------------------------------------------------------------------------------
! Version: 1.0.0
! LAPOS_VERSION EQUATE('1.0.0')
! T�picamente incluir este archivo en "Before Global INCLUDE"
!
! Gustavo Saracca (c) 2009-2026
!
! INCLUDE : LAPOS
! -------------------------------------------------------------------------------------------------

    pragma( 'link(..\lapos\lapos.lib)' )
    map
        module('lapos.dll')
            lapos_setCom  ( long ),dll,raw,c
            lapos_purchase( *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring ),long,dll,raw,c

            lapos_purchase_extra_cash( *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring ),long,dll,raw,c

            lapos_void( *cstring, *cstring, *cstring, *cstring, |
                        *cstring, *cstring, *cstring, *cstring, |
                        *cstring, *cstring, *cstring, *cstring, |
                        *cstring, *cstring, *cstring ),long,dll,raw,c

            lapos_refund  ( *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring, |
                            *cstring, *cstring, *cstring, *cstring, *cstring ),long,dll,raw,c

            lapos_export  (),dll,raw,c
            lapos_test    (),long,dll,raw,c
            lapos_batch_close( *cstring, *cstring, *cstring, *cstring ),long,dll,raw,c
            lapos_batch_print(),long,dll,raw,c
            lapos_print_ticket(),long,dll,raw,c
            lapos_get_batch( long, |
                             *cstring, *cstring, *cstring, |
                             *cstring, *cstring, *cstring, *cstring, |
                             *cstring, *cstring, *cstring, *cstring, |
                             *cstring, *cstring, *cstring ),long,dll,raw,c
             lapos_get_tarjeta( long, *cstring, *cstring, *cstring, *cstring, *cstring ),long,dll,raw,c
             lapos_get_plan   ( long, *cstring, *cstring, *cstring, *cstring ),long,dll,raw,c
        end !* module *
    end !* map *    

!* end *