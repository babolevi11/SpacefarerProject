@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'State of matter value help'
//@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZI_STATE_OF_MATTER_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name : 'ZDOM_STATE_OF_MATTER' ) as Values
  left outer join DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name : 'ZDOM_STATE_OF_MATTER' ) as Texts
    on  Texts.domain_name    = Values.domain_name
    and Texts.value_position = Values.value_position
    and Texts.language       = $session.system_language
{
      @ObjectModel.text.element: ['Description'] // Tells Fiori to grab the description text
  key Values.value_low       as StateOfMatterCode,
  
      @Semantics.text: true
      Texts.text             as Description
}
