@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Wealth of of the Spacefarers'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_WEALT_AGG
  as select from    ZR_SPACEF         as Spacefarer
    left outer join ZI_DUST_VALUE_AGG as DustAggregate on Spacefarer.SpacefarerId = DustAggregate.SpacefarerId
{
  key Spacefarer.SpacefarerId,
      Spacefarer.SpacefarerName,
      Spacefarer.Credits,
      coalesce( DustAggregate.TotalItemCount, 0 )                      as TotalItemCount,
      Spacefarer.Credits + coalesce( DustAggregate.TotalDustValue, 0 ) as TotalWealth
}
