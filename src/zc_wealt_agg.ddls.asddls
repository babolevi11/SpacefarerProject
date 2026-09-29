@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view for wealt Aggregation'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_WEALT_AGG as select from ZI_WEALT_AGG
{
  @UI.facet: [ { id: 'Collection', type: #COLLECTION, label: 'Wealth Details' } ]

  @UI.lineItem: [{ position: 10 }]
  @UI.identification: [{ position: 10 }]
  key SpacefarerId,
  
  @UI.lineItem: [{ position: 20 }]
  @UI.identification: [{ position: 20 }]
  SpacefarerName,
  
  @UI.lineItem: [{ position: 30 }]
  @UI.identification: [{ position: 30 }]
  Credits,
  
  @UI.lineItem: [{ position: 40 }]
  @UI.identification: [{ position: 40 }]
  TotalItemCount,
  
  @UI.lineItem: [{ position: 50 }]
  @UI.identification: [{ position: 50 }]
  TotalWealth
}
