CLASS lhc_zr_stardust_ledger DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR zr_stardust_ledger RESULT result.

*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      REQUEST requested_authorizations FOR zr_stardust_ledger RESULT result.

ENDCLASS.

CLASS lhc_zr_stardust_ledger IMPLEMENTATION.

  METHOD get_instance_authorizations.
*    " Simulating a successful authorization check for the preview
*    result-%create = if_abap_behv=>auth-allowed.
*    result-%update = if_abap_behv=>auth-allowed.
*    result-%delete = if_abap_behv=>auth-allowed.

    " Loop through requested keys and grant access to each row
      LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
        APPEND VALUE #( %tky    = <fs_key>-%tky
                        %update = if_abap_behv=>auth-allowed )
*                        %delete = if_abap_behv=>auth-allowed )
                        TO result.
      ENDLOOP.
  ENDMETHOD.

*  METHOD get_global_authorizations.
*      " In strict(2), global authorization only evaluates general creation rights
*      IF requested_authorizations-%create = if_abap_behv=>mk-on.
*        result-%create = if_abap_behv=>auth-allowed.
*      ENDIF.
*  ENDMETHOD.

ENDCLASS.
