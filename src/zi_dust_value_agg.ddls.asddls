@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Aggregate view for Stardust per Spacefarer'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_DUST_VALUE_AGG
  as select from zbl0923_t_sd_col
{
  key spacefarer_id             as SpacefarerId,
      sum( value )              as TotalDustValue,
      count( distinct item_id ) as TotalItemCount
}
group by
  spacefarer_id
