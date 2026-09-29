@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value help for stardust color'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_DUST_COLOR_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name : 'ZDOM_DUST_COLOR' )
{
      @UI.hidden: true
  key domain_name    as DomainName,
      @UI.hidden: true
  key value_position as ValuePosition,
      @EndUserText.label: 'Selection Value'
  key value_low      as DustColor
}
