@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help Data Modell view for Wormhole Navigation skills'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_NAVIGATION_SKILLS_VH
  as select from    DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name : 'ZDOM_NAVIGATION_SKILLS' )   as Values
    left outer join DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name : 'ZDOM_NAVIGATION_SKILLS' ) as Texts on  Texts.domain_name    = Values.domain_name
                                                                                                       and Texts.value_position = Values.value_position
                                                                                                       and Texts.language       = $session.system_language
{
      @ObjectModel.text.element: ['Description']
  key Values.value_low as NavigationSkill,

      @Semantics.text: true
      Texts.text       as Description
}
