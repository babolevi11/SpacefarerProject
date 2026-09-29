@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Planets and Suitcolor'
@ObjectModel.resultSet.sizeCategory: #XS
//@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_PLANET_SUITCOLOR
  as select from zbl0923_t_pltcol
{
  key planet     as Planet,
      suit_color as SuitColor,
      last_changed_at  as LastChangedAt
}
