//@AbapCatalog.sqlViewName: ''
//@AbapCatalog.compiler.compareFilter: true
//@AbapCatalog.preserveKey: true
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Accept and Reject Value Help'
@ObjectModel.dataCategory: #TEXT
//@Metadata.ignorePropagatedAnnotations: true
define view entity zi_accep_reject_vh
            as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name : 'ZDOM_ACCEP_REJECT' ) as Values
            left outer join DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name : 'ZDOM_ACCEP_REJECT' ) as Texts 
                        on  Texts.domain_name    = Values.domain_name
                        and Texts.value_position = Values.value_position
                        and Texts.language       = $session.system_language
{
      @ObjectModel.text.element: [ 'Description' ]
  key Values.value_low as StatusValue,
      
      @EndUserText.label: 'Status Description'
      Texts.text       as Description
}
