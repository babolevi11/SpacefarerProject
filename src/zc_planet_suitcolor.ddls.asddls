@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view for Planet and Spacesuit maintanence'
//@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define root view entity ZC_PLANET_SUITCOLOR
  provider contract transactional_query
  as projection on ZI_PLANET_SUITCOLOR
{
      @UI.facet: [ { id: 'idIdentification', type: #IDENTIFICATION_REFERENCE, label: 'Planet Config' } ]

      @UI.lineItem: [ { position: 10 } ]
      @UI.identification: [ { position: 10 } ]
      @Search.defaultSearchElement: true
  key Planet,

      @UI.lineItem: [ { position: 20 } ]
      @UI.identification: [ { position: 20 } ]
      SuitColor
}
