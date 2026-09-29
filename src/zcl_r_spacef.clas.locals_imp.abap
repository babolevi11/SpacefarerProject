" ==========================================
" STEP 1: Put this at the very top of the file
" ==========================================
CLASS lcl_ledger_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA mt_ledger_entries TYPE TABLE OF zbl0923_t_tr_gl.
    CLASS-DATA mt_update_items   TYPE TABLE OF sysuuid_x16.
ENDCLASS.

CLASS lcl_ledger_buffer IMPLEMENTATION.
ENDCLASS.

CLASS lhc_zr_sd_col DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    TYPES ty_stardust_items TYPE TABLE FOR READ RESULT zr_spacef\\zr_sd_col.

    METHODS offerForSale FOR MODIFY
       keys FOR ACTION ZR_sd_col~offerForSale RESULT result.
    METHODS buyStardust FOR MODIFY
       keys FOR ACTION zr_sd_col~buyStardust RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR zr_sd_col RESULT result.
    METHODS exchangestardust FOR MODIFY
       keys FOR ACTION zr_sd_col~exchangestardust RESULT result.
    METHODS acceptexchange FOR MODIFY
       keys FOR ACTION zr_sd_col~acceptexchange RESULT result.
    METHODS removeFromSale FOR MODIFY
       keys FOR ACTION zr_sd_col~removefromsale RESULT result.

ENDCLASS.

CLASS lhc_zr_sd_col IMPLEMENTATION.

  METHOD removefromsale.
    " 2. Read the selected Stardust records from the transactional buffer
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        FIELDS ( ItemId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_stardust_items)
      FAILED DATA(lt_read_failed).

    IF lt_read_failed IS NOT INITIAL.
      failed = CORRESPONDING #( lt_read_failed ).
      RETURN.
    ENDIF.

    DATA: lt_stardust_to_update TYPE TABLE FOR UPDATE zr_spacef\\zr_sd_col.

    " 3. Loop through the selected items and prepare the update state
    LOOP AT lt_stardust_items ASSIGNING FIELD-SYMBOL(<ls_stardust>).
      APPEND VALUE #( ItemId        = <ls_stardust>-ItemId
                    IsForSale     = abap_false       " Marks it as blank
                    Value         = 0 " Set value back to zero
                    %control      = VALUE #( IsForSale = if_abap_behv=>mk-on
                                             Value     = if_abap_behv=>mk-on )
                  ) TO lt_stardust_to_update.
    ENDLOOP.

    " If validation issues occur, block database saves
    IF failed-zr_sd_col IS NOT INITIAL.
      RETURN.
    ENDIF.

    " Execute the managed transactional state update
    MODIFY ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        UPDATE FIELDS ( IsForSale Value ) WITH lt_stardust_to_update
      MAPPED DATA(lt_modify_mapped)
      FAILED DATA(lt_modify_failed)
      REPORTED DATA(lt_modify_reported).

    IF lt_modify_failed IS NOT INITIAL.
      failed   = CORRESPONDING #( lt_modify_failed ).
      reported = CORRESPONDING #( lt_modify_reported ).
      RETURN.
    ENDIF.

    " 5. Fill out the mandatory return 'result' structure so Fiori Elements refreshes the screen data layout instantly
    result = VALUE #( FOR ls_mapped IN lt_stardust_to_update (
                        ItemId = ls_mapped-ItemId ) ).
  ENDMETHOD.

  METHOD offerForSale.
    " 1. Copy keys into a flat standard table to completely bypass the framework's strict sorted key index checks
    TYPES: BEGIN OF ts_flat_key,
             item_id  TYPE sysuuid_x16,
             param_pr TYPE p LENGTH 8 DECIMALS 0,
           END OF ts_flat_key.
    DATA: lt_flat_keys TYPE STANDARD TABLE OF ts_flat_key WITH EMPTY KEY.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_raw_key>).
      APPEND VALUE #( item_id  = <ls_raw_key>-ItemId
                      param_pr = <ls_raw_key>-%param-price_in_credits
                    ) TO lt_flat_keys.
    ENDLOOP.

    " 2. Read the selected Stardust records from the transactional buffer
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        FIELDS ( ItemId SpacefarerId IsForSale Value )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_stardust_items)
      FAILED DATA(lt_read_failed).

    IF lt_read_failed IS NOT INITIAL.
      failed = CORRESPONDING #( lt_read_failed ).
      RETURN.
    ENDIF.

    DATA: lt_stardust_to_update TYPE TABLE FOR UPDATE zr_spacef\\zr_sd_col.

    " 3. Loop through the selected items and prepare the update state
    LOOP AT lt_stardust_items ASSIGNING FIELD-SYMBOL(<ls_stardust>).
      " Look up our clean, un-indexed local table
      READ TABLE lt_flat_keys WITH KEY item_id = <ls_stardust>-ItemId
           ASSIGNING FIELD-SYMBOL(<ls_flat_key>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

*      DATA(lv_is_for_sale) = <ls_stardust>-IsForSale.
      DATA(lv_asking_price) = <ls_flat_key>-param_pr.

      IF <ls_stardust>-IsForSale = abap_false.
        " Business Rule Validation: Ensure the price is greater than 0
        IF lv_asking_price <= 0." AND <ls_stardust>-IsForSale = abap_false."
          APPEND VALUE #( ItemId = <ls_stardust>-ItemId
                          %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class number = '007' severity = if_abap_behv_message=>severity-error )
                        ) TO reported-zr_sd_col.

          APPEND VALUE #( ItemId = <ls_stardust>-ItemId ) TO failed-zr_sd_col.
          CONTINUE.
        ENDIF.
        " 4. Map the fields to change for the Managed Save Sequence
        APPEND VALUE #( ItemId        = <ls_stardust>-ItemId
                        IsForSale     = abap_true       " Marks it as 'X'
                        Value         = lv_asking_price " Updates the asset price value field
                        %control      = VALUE #( IsForSale = if_abap_behv=>mk-on
                                                 Value     = if_abap_behv=>mk-on )
                      ) TO lt_stardust_to_update.
      ELSE.
        APPEND VALUE #( ItemId        = <ls_stardust>-ItemId
                      IsForSale     = abap_false       " Marks it as 'X'
                      Value         = 0 " Updates the asset price value field
                      %control      = VALUE #( IsForSale = if_abap_behv=>mk-on
                                               Value     = if_abap_behv=>mk-on )
                    ) TO lt_stardust_to_update.
      ENDIF.
    ENDLOOP.

    " If validation issues occur, block database saves
    IF failed-zr_sd_col IS NOT INITIAL.
      RETURN.
    ENDIF.

    " Execute the managed transactional state update
    MODIFY ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        UPDATE FIELDS ( IsForSale Value ) WITH lt_stardust_to_update
      MAPPED DATA(lt_modify_mapped)
      FAILED DATA(lt_modify_failed)
      REPORTED DATA(lt_modify_reported).

    IF lt_modify_failed IS NOT INITIAL.
      failed   = CORRESPONDING #( lt_modify_failed ).
      reported = CORRESPONDING #( lt_modify_reported ).
      RETURN.
    ENDIF.

    " 5. Fill out the mandatory return 'result' structure so Fiori Elements refreshes the screen data layout instantly
    result = VALUE #( FOR ls_mapped IN lt_stardust_to_update (
                        ItemId = ls_mapped-ItemId
*                        %param = CORRESPONDING #( lt_stardust_items[ ItemId = ls_mapped-ItemId ] )
                        %param = CORRESPONDING #( VALUE #( lt_stardust_items[ KEY entity COMPONENTS itemid = ls_mapped-ItemId ] ) )
                      ) ).
  ENDMETHOD.

  METHOD buyStardust.
    CLEAR: failed, reported, result.

    " 1. Read the Stardust item selected on the UI screen
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_selected_items).

    DATA lt_stardust_updates   TYPE TABLE FOR UPDATE zr_spacef\\zr_sd_col.
    DATA lt_spacefarer_updates TYPE TABLE FOR UPDATE zr_spacef.
    DATA lt_db_ledger          TYPE TABLE OF zbl0923_t_tr_gl.

    GET TIME STAMP FIELD DATA(lv_current_timestamp).

    " 2. Loop through selected purchase records
    LOOP AT lt_selected_items ASSIGNING FIELD-SYMBOL(<ls_stardust>).

      " Securely grab popup parameters matching your exact ZA_BUYER_PARAM field payload structure
      DATA(ls_param) = VALUE #( keys[ KEY entity COMPONENTS %tky = <ls_stardust>-%tky ]-%param OPTIONAL ).

      " --- Validation Checks ---
      " Rule A: Ensure the item is actively flagged for sale
      IF <ls_stardust>-IsForSale <> abap_true.
        APPEND VALUE #( %tky = <ls_stardust>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_stardust>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class number = '001' severity = if_abap_behv_message=>severity-error ) ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " Rule B: Prevent buying an item you already own
      IF <ls_stardust>-SpacefarerId = ls_param-BuyerSpacefarerId.
        APPEND VALUE #( %tky = <ls_stardust>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_stardust>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class number = '002' severity = if_abap_behv_message=>severity-error ) ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " 3. Read the Buyer profile info
      READ ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_spacef
          FIELDS ( Credits Reputation )
          WITH VALUE #( ( SpacefarerId = ls_param-BuyerSpacefarerId ) )
        RESULT DATA(lt_buyer_data).

      READ TABLE lt_buyer_data INTO DATA(ls_buyer) INDEX 1.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <ls_stardust>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_stardust>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class number = '003' severity = if_abap_behv_message=>severity-error ) ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " 4. Read the Seller profile info (The current owner of the stardust record)
      READ ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_spacef
          FIELDS ( Credits Reputation )
          WITH VALUE #( ( SpacefarerId = <ls_stardust>-SpacefarerId ) )
        RESULT DATA(lt_seller_data).

      READ TABLE lt_seller_data INTO DATA(ls_seller) INDEX 1.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <ls_stardust>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_stardust>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class number = '004' severity = if_abap_behv_message=>severity-error ) ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " ─── CALCULATE BUYER COST ───
      DATA(lv_buyer_cost) = <ls_stardust>-Value.
*    DATA(lv_buyer_mod_pct) = 0.
      DATA lv_buyer_mod_pct TYPE decfloat16 VALUE 0.

      IF ls_buyer-Reputation > 30.
        " Every +5 reputation gives 1% discount
        lv_buyer_mod_pct = ( ls_buyer-Reputation - 30 ) / 5.
        lv_buyer_cost    = <ls_stardust>-Value * ( 100 - lv_buyer_mod_pct ) / 100.
      ELSEIF ls_buyer-Reputation < 30.
        " Every -5 reputation gives 1% increased price
        lv_buyer_mod_pct = ( 30 - ls_buyer-Reputation ) / 5.
        lv_buyer_cost    = <ls_stardust>-Value * ( 100 + lv_buyer_mod_pct ) / 100.
      ENDIF.

      " ─── CALCULATE SELLER PROFIT ───
      DATA(lv_seller_profit) = <ls_stardust>-Value.
      DATA(lv_seller_difference) = <ls_stardust>-Value.
      DATA lv_seller_mod_pct TYPE decfloat16 VALUE 0.

      IF ls_seller-Reputation > 30.
        " Every +5 reputation gives 1% more profit
        lv_seller_mod_pct = ( ls_seller-Reputation - 30 ) / 5.
        lv_seller_profit  = <ls_stardust>-Value * ( 100 + lv_seller_mod_pct ) / 100.
      ELSEIF ls_seller-Reputation < 30.
        " Every -5 reputation gives 1% loss
        lv_seller_mod_pct = ( 30 - ls_seller-Reputation ) / 5.
        lv_seller_profit  = <ls_stardust>-Value * ( 100 - lv_seller_mod_pct ) / 100.
      ENDIF.
      lv_seller_difference = lv_seller_profit - <ls_stardust>-Value.
      lv_buyer_cost += lv_seller_difference.
      " Rule C: Check credit availability against calculated buyer cost
      IF ls_buyer-Credits < lv_buyer_cost.
        APPEND VALUE #( %tky = <ls_stardust>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_stardust>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class number = '007' severity = if_abap_behv_message=>severity-error ) ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " 5. Update the item ownership and close it from being for sale
      APPEND VALUE #(
        %tky           = <ls_stardust>-%tky
        SpacefarerId   = ls_param-BuyerSpacefarerId
        IsForSale      = abap_false
        ExchangeStatus = ''
        %control       = VALUE #( SpacefarerId   = if_abap_behv=>mk-on
                                  IsForSale      = if_abap_behv=>mk-on
                                  ExchangeStatus = if_abap_behv=>mk-on )
      ) TO lt_stardust_updates.

      " 6. Debit the Buyer credits account
      APPEND VALUE #(
        SpacefarerId   = ls_param-BuyerSpacefarerId
        Credits        = ls_buyer-Credits - lv_buyer_cost
        %control       = VALUE #( Credits = if_abap_behv=>mk-on )
      ) TO lt_spacefarer_updates.

      " 7. Credit the Seller credits account with profit payout
      APPEND VALUE #(
        SpacefarerId   = <ls_stardust>-SpacefarerId
        Credits        = ls_seller-Credits + lv_buyer_cost
        %control       = VALUE #( Credits = if_abap_behv=>mk-on )
      ) TO lt_spacefarer_updates.

      " 8. Prepare ledger entry logging final audited amounts
      APPEND VALUE #(
        transaction_id       = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        stardust_id          = <ls_stardust>-ItemId
        from_spacefarer_id   = <ls_stardust>-SpacefarerId
        from_spacefarer_name = <ls_stardust>-SpacefarerName
        state_of_matter      = <ls_stardust>-StateOfMatter
        color_of_dust        = <ls_stardust>-ColorOfDust
        weight               = <ls_stardust>-Weight
        weight_unit          = <ls_stardust>-WeightUnit
        to_spacefarer_id     = ls_param-BuyerSpacefarerId
        to_spacefarer_name   = ls_param-BuyerSpacefarerName
        trade_type           = 'BUY'
        exchange_type        = 'COMPLETED'
        price_in_credits     = lv_buyer_cost " This represents the final price charged
        created_at           = lv_current_timestamp
      ) TO lt_db_ledger.


    ENDLOOP.

    " 9. Execute balanced modifications to active instances
    IF lt_stardust_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_sd_col
          UPDATE FIELDS ( SpacefarerId IsForSale ExchangeStatus ) WITH lt_stardust_updates
        ENTITY zr_spacef
          UPDATE FIELDS ( Credits ) WITH lt_spacefarer_updates
        FAILED DATA(lt_mod_failed)
        REPORTED DATA(lt_mod_reported).

      failed   = CORRESPONDING #( DEEP lt_mod_failed ).
      reported = CORRESPONDING #( DEEP lt_mod_reported ).
    ENDIF.

    " 10. Pass to the Save Sequence buffer safely
    IF failed IS INITIAL AND lt_db_ledger IS NOT INITIAL.
      APPEND LINES OF lt_db_ledger TO lcl_ledger_buffer=>mt_ledger_entries.
      result = VALUE #( FOR ls_item IN lt_selected_items ( %tky = ls_item-%tky %param = ls_item ) ).
    ENDIF.
  ENDMETHOD.

  METHOD exchangeStardust.
    CLEAR: failed, reported, result.

    " 1. Read the Offerer's Stardust item selected on the UI screen
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_offered_items).

    DATA lt_stardust_updates TYPE TABLE FOR UPDATE zr_spacef\\zr_sd_col.
    DATA lt_db_ledger        TYPE TABLE OF zbl0923_t_tr_gl.

    GET TIME STAMP FIELD DATA(lv_current_timestamp).

    " 2. Loop through selections to process the proposal
    LOOP AT lt_offered_items ASSIGNING FIELD-SYMBOL(<ls_offered_item>).

      " Grab your single item parameter from the UI layout popup
      DATA(ls_param) = VALUE #( keys[ KEY entity COMPONENTS %tky = <ls_offered_item>-%tky ]-%param OPTIONAL ).

      " --- Validation Checks ---
      " Rule A: Ensure your own item isn't already locked in another pending trade
      IF <ls_offered_item>-ExchangeStatus = 'PENDING' OR <ls_offered_item>-ExchangeStatus = 'INC_OFFER'.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class
                        number = '012'
                        severity = if_abap_behv_message=>severity-error )
                        ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " 3. Read the requested target item from the database using your updated single field
      READ ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_sd_col
          ALL FIELDS
          WITH VALUE #( ( ItemId = ls_param-OfferedInExchangedForId ) )
        RESULT DATA(lt_receiver_items).

      READ TABLE lt_receiver_items ASSIGNING FIELD-SYMBOL(<ls_receiver_item>) INDEX 1.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class
                        number = '011'
                        severity = if_abap_behv_message=>severity-error )
                        ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " Rule B: Ensure the receiver's item isn't locked down or already pending another deal
      IF <ls_receiver_item>-ExchangeStatus = 'PENDING' OR <ls_receiver_item>-ExchangeStatus = 'INC_OFFER'.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class
                        number = '012'
                        severity = if_abap_behv_message=>severity-error )
                        ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " ─── NEW LOOKUP: Fetch the Receiver's Name via their SpacefarerId ───
      READ ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_spacef
          FIELDS ( SpacefarerName )
          WITH VALUE #( ( SpacefarerId = <ls_receiver_item>-SpacefarerId ) )
        RESULT DATA(lt_receiver_profile).

      DATA(lv_receiver_name) = VALUE string( lt_receiver_profile[ 1 ]-SpacefarerName OPTIONAL ).
      " ────────────────────────────────────────────────────────────────────
      IF <ls_offered_item>-SpacefarerName = lv_receiver_name.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_offered_item>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class
                        number = '013'
                        severity = if_abap_behv_message=>severity-error )
                        ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.
      " 4. Update the Offerer's selected asset item using lookups
      APPEND VALUE #(
        %tky                  = <ls_offered_item>-%tky
        ExchangeStatus        = 'PENDING'
        OfferedToId           = <ls_receiver_item>-SpacefarerId   " Derived from item read
        OfferedToName         = lv_receiver_name                  " Derived from profile read
        OfferedInExchangedFor = ls_param-OfferedInExchangedForId  " Param input field
        %control              = VALUE #( ExchangeStatus        = if_abap_behv=>mk-on
                                         OfferedToId           = if_abap_behv=>mk-on
                                         OfferedToName         = if_abap_behv=>mk-on
                                         OfferedInExchangedFor = if_abap_behv=>mk-on )
      ) TO lt_stardust_updates.

      " 5. Update the Receiver's asset item to also mark it as Pending
      APPEND VALUE #(
*        %tky-SpacefarerId = <ls_receiver_item>-SpacefarerId
*        %tky-spa = <ls_receiver_item>-SpacefarerId
        %tky-ItemId       = <ls_receiver_item>-ItemId
*        ExchangeStatus    = 'PENDING'
        ExchangeStatus    = 'INC_OFFER'
        %control          = VALUE #( ExchangeStatus = if_abap_behv=>mk-on )
      ) TO lt_stardust_updates.


      " 6. Ledger Line 1: For the person who asked for the exchange (Proposed)
      APPEND VALUE #(
        transaction_id       = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        stardust_id          = <ls_offered_item>-ItemId
        from_spacefarer_id   = <ls_offered_item>-SpacefarerId
        from_spacefarer_name = <ls_offered_item>-SpacefarerName
        state_of_matter      = <ls_offered_item>-StateOfMatter
        color_of_dust        = <ls_offered_item>-ColorOfDust
        weight               = <ls_offered_item>-Weight
        weight_unit          = <ls_offered_item>-WeightUnit
        to_spacefarer_id     = <ls_receiver_item>-SpacefarerId
        to_spacefarer_name   = lv_receiver_name
        trade_type           = 'EXCHANGE'
        exchange_type        = 'PROPOSED'
        price_in_credits     = 0
        created_at           = lv_current_timestamp
      ) TO lt_db_ledger.

      " 7. Ledger Line 2: For the receiver party who will see an incoming offer (Incoming)
      APPEND VALUE #(
        transaction_id       = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        stardust_id          = <ls_receiver_item>-ItemId
        from_spacefarer_id   = <ls_receiver_item>-SpacefarerId
        from_spacefarer_name = <ls_receiver_item>-SpacefarerName
        state_of_matter      = <ls_receiver_item>-StateOfMatter
        color_of_dust        = <ls_receiver_item>-ColorOfDust
        weight               = <ls_receiver_item>-Weight
        weight_unit          = <ls_receiver_item>-WeightUnit
        to_spacefarer_id     = <ls_offered_item>-SpacefarerId
        to_spacefarer_name   = <ls_offered_item>-SpacefarerName
        trade_type           = 'EXCHANGE'
        exchange_type        = 'INCOMING'
        price_in_credits     = 0
        created_at           = lv_current_timestamp
      ) TO lt_db_ledger.

    ENDLOOP.

    " 8. Execute modifications to the active application instances
    IF lt_stardust_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_sd_col
          UPDATE FIELDS ( ExchangeStatus OfferedToId OfferedToName OfferedInExchangedFor ) WITH lt_stardust_updates
        FAILED DATA(lt_mod_failed)
        REPORTED DATA(lt_mod_reported).

      failed   = CORRESPONDING #( DEEP lt_mod_failed ).
      reported = CORRESPONDING #( DEEP lt_mod_reported ).
    ENDIF.

    " 9. Pass ledger records safely to our transactional save sequence buffer
    IF failed IS INITIAL AND lt_db_ledger IS NOT INITIAL.
      APPEND LINES OF lt_db_ledger TO lcl_ledger_buffer=>mt_ledger_entries.
      result = VALUE #( FOR ls_item IN lt_offered_items ( %tky = ls_item-%tky %param = ls_item ) ).
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
    " 1. Read the necessary state fields from the buffer/database
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        FIELDS ( ExchangeStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_stardust)
      FAILED DATA(lt_failed).

    " 2. Loop through rows and construct responses inline
    LOOP AT lt_stardust ASSIGNING FIELD-SYMBOL(<ls_stardust>).

      APPEND VALUE #(
        %tky = <ls_stardust>-%tky " Identifies the specific entity instance

        " Map custom entity actions
        %features-%action-offerForSale     = COND #( WHEN <ls_stardust>-ExchangeStatus = 'PENDING'
                                                       OR <ls_stardust>-ExchangeStatus = 'INC_OFFER'
                                                       OR <ls_stardust>-isforsale = abap_false
                                                     THEN if_abap_behv=>fc-o-disabled
                                                     ELSE if_abap_behv=>fc-o-enabled )

        %features-%action-buyStardust     = COND #( WHEN <ls_stardust>-ExchangeStatus = 'PENDING' OR <ls_stardust>-ExchangeStatus = 'INC_OFFER'
                                                     THEN if_abap_behv=>fc-o-disabled
                                                     ELSE if_abap_behv=>fc-o-enabled )

        %features-%action-exchangeStardust = COND #( WHEN <ls_stardust>-ExchangeStatus = 'PENDING' OR <ls_stardust>-ExchangeStatus = 'INC_OFFER'
                                                     THEN if_abap_behv=>fc-o-disabled
                                                     ELSE if_abap_behv=>fc-o-enabled )

        %features-%action-acceptExchange   = COND #( WHEN <ls_stardust>-ExchangeStatus = 'INC_OFFER'
                                                     THEN if_abap_behv=>fc-o-enabled
                                                     ELSE if_abap_behv=>fc-o-disabled )

        %features-%action-removefromsale   = COND #( WHEN <ls_stardust>-isforsale = abap_true
                                                     THEN if_abap_behv=>fc-o-enabled
                                                     ELSE if_abap_behv=>fc-o-disabled )
      ) TO result.

    ENDLOOP.
  ENDMETHOD.

  METHOD acceptExchange.
    CLEAR: failed, reported, result.

    " 1. Read the Receiver's item (the item currently selected to accept the trade)
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_sd_col
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_receiver_items).

    DATA lt_stardust_updates TYPE TABLE FOR UPDATE zr_spacef\\zr_sd_col.
    DATA lt_db_ledger        TYPE TABLE OF zbl0923_t_tr_gl.
    DATA lv_accept_reject    TYPE zde_exchange_type.

    GET TIME STAMP FIELD DATA(lv_current_timestamp).

    " 2. Loop through selections to finalize the trade swap
    LOOP AT lt_receiver_items ASSIGNING FIELD-SYMBOL(<ls_receiver_item>).

      DATA(ls_param) = VALUE #( keys[ KEY entity COMPONENTS %tky = <ls_receiver_item>-%tky ]-%param OPTIONAL ).

      IF ls_param-AcceptReject = 'ACCEPT'.
        lv_accept_reject = 'COMPLETED'.
      ELSE.
        lv_accept_reject = 'REJECTED'.
      ENDIF.

      " Find the companion offered item that initiated this transaction.
      " We execute an optimized Open SQL query against the underlying base table.
      SELECT SINGLE *
        FROM zbl0923_t_sd_col
        WHERE offered_in_exch_for = @<ls_receiver_item>-ItemId
        INTO @DATA(ls_offered_db_row).

      " If it is not found in the active table, check the draft table buffer
      IF sy-subrc <> 0.
        SELECT SINGLE *
          FROM zbl_sd_col_d
          WHERE offeredinexchangedfor = @<ls_receiver_item>-ItemId
          INTO CORRESPONDING FIELDS OF @ls_offered_db_row.
      ENDIF.

      " If neither table contains the reference, raise a processing error
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <ls_receiver_item>-%tky ) TO failed-zr_sd_col.
        APPEND VALUE #( %tky = <ls_receiver_item>-%tky
                        %msg = new_message( id = zif_spacefarer_constants=>cv_msg_class number = '015' severity = if_abap_behv_message=>severity-error ) ) TO reported-zr_sd_col.
        CONTINUE.
      ENDIF.

      " Map the database fields into a work area and assign to the unified field-symbol
      DATA ls_offered_item TYPE zr_sd_col.
      " Map corresponding fields manually or via matching properties
      ls_offered_item-ItemId            = ls_offered_db_row-item_id.
      ls_offered_item-SpacefarerId     = ls_offered_db_row-spacefarer_id.
      ls_offered_item-StateOfMatter    = ls_offered_db_row-state_of_matter.
      ls_offered_item-ColorOfDust      = ls_offered_db_row-color_of_dust.
      ls_offered_item-Weight           = ls_offered_db_row-weight.
      ls_offered_item-WeightUnit       = 'G'. " Constant fallback from view configuration

      ASSIGN ls_offered_item TO FIELD-SYMBOL(<ls_offered_item>).

      " --- Dual Profile Verification ---
      " Fetch names for the final transaction ledger entry histories
      READ ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_spacef
          FIELDS ( SpacefarerName )
          WITH VALUE #( ( SpacefarerId = <ls_offered_item>-SpacefarerId )
                        ( SpacefarerId = <ls_receiver_item>-SpacefarerId ) )
        RESULT DATA(lt_spacefarer_profiles).

      DATA(lv_offered_owner_name)  = VALUE string( lt_spacefarer_profiles[ SpacefarerId = <ls_offered_item>-SpacefarerId ]-SpacefarerName OPTIONAL ).
      DATA(lv_receiver_owner_name) = VALUE string( lt_spacefarer_profiles[ SpacefarerId = <ls_receiver_item>-SpacefarerId ]-SpacefarerName OPTIONAL ).

      IF ls_param-AcceptReject = 'ACCEPT'.
        " 3. SWAP OWNERSHIP: Update the Offerer's Item (Give it to the Receiver)
        APPEND VALUE #(
          %tky-ItemId           = <ls_offered_item>-ItemId
          SpacefarerId          = <ls_receiver_item>-SpacefarerId " New Owner ID
          ExchangeStatus        = ''                              " Reset status
          IsForSale             = abap_false                      " Close from market listing
          OfferedToId           = ''
          OfferedToName         = ''
          OfferedInExchangedFor = VALUE #( )                      " Clear key reference
          %control              = VALUE #( SpacefarerId          = if_abap_behv=>mk-on
                                           ExchangeStatus        = if_abap_behv=>mk-on
                                           IsForSale             = if_abap_behv=>mk-on
                                           OfferedToId           = if_abap_behv=>mk-on
                                           OfferedToName         = if_abap_behv=>mk-on
                                           OfferedInExchangedFor = if_abap_behv=>mk-on )
        ) TO lt_stardust_updates.

        " 4. SWAP OWNERSHIP: Update the Receiver's Item (Give it to the Offerer)
        APPEND VALUE #(
          %tky-ItemId           = <ls_receiver_item>-ItemId
          SpacefarerId          = <ls_offered_item>-SpacefarerId  " New Owner ID
          ExchangeStatus        = ''                              " Reset status
          IsForSale             = abap_false                      " Close from market listing
          OfferedToId           = ''
          OfferedToName         = ''
          OfferedInExchangedFor = VALUE #( )                      " Clear key reference
          %control              = VALUE #( SpacefarerId          = if_abap_behv=>mk-on
                                           ExchangeStatus        = if_abap_behv=>mk-on
                                           IsForSale             = if_abap_behv=>mk-on
                                           OfferedToId           = if_abap_behv=>mk-on
                                           OfferedToName         = if_abap_behv=>mk-on
                                           OfferedInExchangedFor = if_abap_behv=>mk-on )
        ) TO lt_stardust_updates.
      ELSE.
        " 3. KEEP OWNERSHIP: Update the Offerer's Item (Give it to the Receiver)
        APPEND VALUE #(
          %tky-ItemId           = <ls_offered_item>-ItemId
          SpacefarerId          = <ls_offered_item>-SpacefarerId
          ExchangeStatus        = ''                              " Reset status
          IsForSale             = abap_false                      " Close from market listing
          OfferedToId           = ''
          OfferedToName         = ''
          OfferedInExchangedFor = VALUE #( )                      " Clear key reference
          %control              = VALUE #( SpacefarerId          = if_abap_behv=>mk-on
                                           ExchangeStatus        = if_abap_behv=>mk-on
                                           IsForSale             = if_abap_behv=>mk-on
                                           OfferedToId           = if_abap_behv=>mk-on
                                           OfferedToName         = if_abap_behv=>mk-on
                                           OfferedInExchangedFor = if_abap_behv=>mk-on )
        ) TO lt_stardust_updates.

        " 4. KEEP OWNERSHIP: Update the Receiver's Item (Give it to the Offerer)
        APPEND VALUE #(
          %tky-ItemId           = <ls_receiver_item>-ItemId
          SpacefarerId          = <ls_receiver_item>-SpacefarerId
          ExchangeStatus        = ''                              " Reset status
          IsForSale             = abap_false                      " Close from market listing
          OfferedToId           = ''
          OfferedToName         = ''
          OfferedInExchangedFor = VALUE #( )                      " Clear key reference
          %control              = VALUE #( SpacefarerId          = if_abap_behv=>mk-on
                                           ExchangeStatus        = if_abap_behv=>mk-on
                                           IsForSale             = if_abap_behv=>mk-on
                                           OfferedToId           = if_abap_behv=>mk-on
                                           OfferedToName         = if_abap_behv=>mk-on
                                           OfferedInExchangedFor = if_abap_behv=>mk-on )
        ) TO lt_stardust_updates.
      ENDIF.
      " ─── NEW STEP: Update the older pending ledger rows to a finalized status ───
      APPEND <ls_offered_item>-ItemId  TO lcl_ledger_buffer=>mt_update_items.
      APPEND <ls_receiver_item>-ItemId TO lcl_ledger_buffer=>mt_update_items.
*    UPDATE zbl0923_t_tr_gl
*       SET exchange_type = 'PROCESSED'
*     WHERE stardust_id   = @<ls_offered_item>-ItemId  AND exchange_type = 'INCOMING'
*        OR stardust_id   = @<ls_receiver_item>-ItemId AND exchange_type = 'INCOMING'.
      " ────────────────────────────────────────────────────────────────────────────


      " 5. Ledger Entry Line 1: Logging the Offerer's finalized asset transfer
      APPEND VALUE #(
        transaction_id       = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        stardust_id          = <ls_offered_item>-ItemId
        from_spacefarer_id   = <ls_offered_item>-SpacefarerId
        from_spacefarer_name = lv_offered_owner_name
        state_of_matter      = <ls_offered_item>-StateOfMatter
        color_of_dust        = <ls_offered_item>-ColorOfDust
        weight               = <ls_offered_item>-Weight
        weight_unit          = <ls_offered_item>-WeightUnit
        to_spacefarer_id     = <ls_receiver_item>-SpacefarerId
        to_spacefarer_name   = lv_receiver_owner_name
        trade_type           = 'EXCHANGE'
        exchange_type        = lv_accept_reject
        price_in_credits     = 0
        created_at           = lv_current_timestamp
      ) TO lt_db_ledger.

      " 6. Ledger Entry Line 2: Logging the Receiver's finalized asset transfer
      APPEND VALUE #(
        transaction_id       = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        stardust_id          = <ls_receiver_item>-ItemId
        from_spacefarer_id   = <ls_receiver_item>-SpacefarerId
        from_spacefarer_name = lv_receiver_owner_name
        state_of_matter      = <ls_receiver_item>-StateOfMatter
        color_of_dust        = <ls_receiver_item>-ColorOfDust
        weight               = <ls_receiver_item>-Weight
        weight_unit          = <ls_receiver_item>-WeightUnit
        to_spacefarer_id     = <ls_offered_item>-SpacefarerId
        to_spacefarer_name   = lv_offered_owner_name
        trade_type           = 'EXCHANGE'
        exchange_type        = lv_accept_reject
        price_in_credits     = 0
        created_at           = lv_current_timestamp
      ) TO lt_db_ledger.

    ENDLOOP.

    " 7. Execute transactional database updates inside local mode
    IF lt_stardust_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_sd_col
          UPDATE FIELDS ( SpacefarerId ExchangeStatus IsForSale OfferedToId OfferedToName OfferedInExchangedFor ) WITH lt_stardust_updates
        FAILED DATA(lt_mod_failed)
        REPORTED DATA(lt_mod_reported).

      failed   = CORRESPONDING #( DEEP lt_mod_failed ).
      reported = CORRESPONDING #( DEEP lt_mod_reported ).
    ENDIF.

    " 8. Write both audited exchange rows to our transactional saver buffer
    IF failed IS INITIAL AND lt_db_ledger IS NOT INITIAL.
      APPEND LINES OF lt_db_ledger TO lcl_ledger_buffer=>mt_ledger_entries.
      result = VALUE #( FOR ls_item IN lt_receiver_items ( %tky = ls_item-%tky %param = ls_item ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      determineSuitColor FOR DETERMINE ON MODIFY
        IMPORTING keys FOR zr_spacef~determineSuitColor,
      validateSkillAndReputation FOR VALIDATE ON SAVE
        IMPORTING keys FOR zr_spacef~validateSkillAndReputation,
      precheck_delete FOR PRECHECK
       keys FOR DELETE zr_spacef,
      get_instance_authorizations FOR INSTANCE AUTHORIZATION
            keys REQUEST requested_authorizations FOR zr_spacef RESULT result.
    " Method 2: Handles authorization for the child node actions (zr_sd_col)
    METHODS get_child_authorizations FOR INSTANCE AUTHORIZATION
            keys REQUEST requested_authorizations FOR zr_sd_col RESULT result_child.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR zr_spacef RESULT result.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD determineSuitColor.
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_spacef
        FIELDS ( OriginPlanet ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_spacefarers).

    DATA lt_update TYPE TABLE FOR UPDATE zr_spacef\\zr_spacef.

    LOOP AT lt_spacefarers ASSIGNING FIELD-SYMBOL(<ls_spacefarer>) WHERE OriginPlanet IS NOT INITIAL.

      SELECT SINGLE suit_color
        FROM zbl0923_t_pltcol
        WHERE planet = @<ls_spacefarer>-OriginPlanet
        INTO @DATA(lv_color).

      IF sy-subrc = 0.
        APPEND VALUE #( %tky       = <ls_spacefarer>-%tky
                        spacesuitcolor  = lv_color
                        %control-spacesuitcolor = if_abap_behv=>mk-on ) TO lt_update.
      ELSE.
        APPEND VALUE #( %tky       = <ls_spacefarer>-%tky
                        spacesuitcolor  = ''
                        %control-spacesuitcolor = if_abap_behv=>mk-on ) TO lt_update.
      ENDIF.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zr_spacef IN LOCAL MODE
        ENTITY zr_spacef
          UPDATE FIELDS ( SpacesuitColor ) WITH lt_update.
    ENDIF.
  ENDMETHOD.

  METHOD validateSkillAndReputation.
    READ ENTITIES OF zr_spacef IN LOCAL MODE
      ENTITY zr_spacef
        FIELDS ( NavigationSkill Reputation )
        WITH CORRESPONDING #( keys )
      RESULT DATA(spacefarers).

    LOOP AT spacefarers ASSIGNING FIELD-SYMBOL(<spacefarer>).
      DATA(lv_skill_num)  = CONV i( <spacefarer>-NavigationSkill ).
      DATA(lv_reputation) = CONV i( <spacefarer>-Reputation ).

      IF ( lv_skill_num + lv_reputation ) >= 99.
        APPEND VALUE #( %tky = <spacefarer>-%tky ) TO failed-zr_spacef.

        APPEND VALUE #(
            %tky                     = <spacefarer>-%tky
            %element-navigationskill = if_abap_behv=>mk-on
            %element-reputation      = if_abap_behv=>mk-on
            %msg                     = new_message(
                                        id = zif_spacefarer_constants=>cv_msg_class
                                        number = '002'
                                        severity = if_abap_behv_message=>severity-error )
        ) TO reported-zr_spacef.
      ELSEIF lv_reputation < 0.
        APPEND VALUE #( %tky = <spacefarer>-%tky ) TO failed-zr_spacef.

        APPEND VALUE #(
            %tky     = <spacefarer>-%tky
            %element-reputation = if_abap_behv=>mk-on
            %msg     = new_message(
                        id = zif_spacefarer_constants=>cv_msg_class
                        number = '003'
                    severity = if_abap_behv_message=>severity-error )
        ) TO reported-zr_spacef.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_delete.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<spacefarer_key>).
      SELECT SINGLE FROM zbl0923_t_sd_col
        FIELDS spacefarer_id
        WHERE spacefarer_id = @<spacefarer_key>-SpacefarerId
        INTO @DATA(lv_active_collection_exists).

      SELECT SINGLE FROM zbl_sd_col_d
        FIELDS spacefarerid
        WHERE spacefarerid = @<spacefarer_key>-SpacefarerId
        INTO @DATA(lv_draft_child_exists).

      IF sy-subrc = 0 OR lv_active_collection_exists IS NOT INITIAL.
        READ ENTITIES OF zr_spacef IN LOCAL MODE
           ENTITY zr_spacef
           FIELDS ( SpacefarerName )
           WITH VALUE #( ( SpacefarerId = <spacefarer_key>-Spacefarerid ) )
           RESULT DATA(lt_spacefarers).

        DATA(lv_name) = VALUE #( lt_spacefarers[ 1 ]-SpacefarerName DEFAULT 'Unknown' ).

        APPEND VALUE #( %tky = <spacefarer_key>-%tky ) TO failed-zr_spacef.

        APPEND VALUE #(
            %tky     = <spacefarer_key>-%tky
            %element = VALUE #( )
            %msg = new_message(
                      id = zif_spacefarer_constants=>cv_msg_class
                      number = '001'
                      severity = if_abap_behv_message=>severity-error
                      v1 = lv_name )
        ) TO reported-zr_spacef.
      ENDIF.

      CLEAR: lv_active_collection_exists, lv_draft_child_exists.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
      APPEND VALUE #( %tky    = <fs_key>-%tky
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed )
                    TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
    " In strict(2), global authorization only evaluates general creation rights
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_child_authorizations.
    " Unconditionally allow operations on child records/actions to satisfy the dump
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_child>).
      APPEND VALUE #( %tky    = <fs_child>-%tky
                      %action-offerForSale    = if_abap_behv=>auth-allowed
                      %action-removefromsale    = if_abap_behv=>auth-allowed
                      %action-buyStardust      = if_abap_behv=>auth-allowed
                      %action-exchangeStardust = if_abap_behv=>auth-allowed
                      %action-acceptExchange   = if_abap_behv=>auth-allowed )
                    TO result_child.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

" ==========================================
" STEP 3: Add this at the very bottom of the file
" ==========================================
CLASS lsc_zr_spacef DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    " ─── UPDATE THE REDEFINITION TO MATCH THE STANDARD SIGNATURE ───
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zr_spacef IMPLEMENTATION.
  METHOD save_modified.
    " 1. Handle updating the older pending ledger rows safely during the save phase
    IF lcl_ledger_buffer=>mt_update_items IS NOT INITIAL.
      UPDATE zbl0923_t_tr_gl
         SET exchange_type = 'PROCESSED'
       WHERE ( exchange_type = 'PROPOSED' OR exchange_type = 'INCOMING' )
         AND stardust_id IN ( SELECT table_line FROM @lcl_ledger_buffer=>mt_update_items AS buffer_table ).
      CLEAR lcl_ledger_buffer=>mt_update_items. " Clear the update buffer
    ENDIF.

    " Handled automatically right before the database COMMIT
    IF lcl_ledger_buffer=>mt_ledger_entries IS NOT INITIAL.
      INSERT zbl0923_t_tr_gl FROM TABLE @lcl_ledger_buffer=>mt_ledger_entries.
      CLEAR lcl_ledger_buffer=>mt_ledger_entries. " Clean buffer for the next request
    ENDIF.

  ENDMETHOD.
ENDCLASS.

