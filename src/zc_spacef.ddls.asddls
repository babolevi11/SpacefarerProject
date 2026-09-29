//@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view for Spacefarer'
//@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: false
define root view entity ZC_SPACEF
  provider contract transactional_query
  as projection on ZR_SPACEF
{
      @UI.facet: [
      { id: 'SpacefarerData',
        purpose: #STANDARD,
        type: #IDENTIFICATION_REFERENCE,
        label: 'General Information',
        position: 10 },

      { id: 'SpacedustCollectionData',
        purpose: #STANDARD,
        type: #LINEITEM_REFERENCE,
        label: 'Collection Items',
        position: 20,
        targetElement: '_SpacedustCollection' }
      ]

//      @UI.lineItem: [ { position: 10 } ]
//      @UI.identification: [ { position: 10 } ]
//      @EndUserText.label: 'Spacefarer ID (Auto-Generated)'
      @UI.hidden: true
  key SpacefarerId,
      @UI.lineItem: [ { position: 10 } ]
      @UI.identification: [ { position: 10 } ]
      @EndUserText.label: 'Spacefarer Name'
      SpacefarerName,
      @Consumption.valueHelpDefinition: [{
      entity: {
        name: 'ZI_NAVIGATION_SKILLS_VH',
        element: 'NavigationSkill'
      }
      }]
      @UI.lineItem: [ { position: 15 } ]
      @UI.identification: [ { position: 15 } ]
      @EndUserText.label: 'Wormhole Navigation Skill'
      NavigationSkill,
      @UI.lineItem: [ { position: 25 } ]
      @UI.identification: [ { position: 25 } ]
      @EndUserText.label: 'Reputation'
      Reputation,
      @UI.lineItem: [ { position: 30 } ]
      @UI.identification: [ { position: 30 } ]
      @EndUserText.label: 'Origin Planet'
      @Consumption.valueHelpDefinition: [{
          entity: { name: 'ZI_PLANET_SUITCOLOR', element: 'Planet' }
      }]
      OriginPlanet,
      @UI.lineItem: [ { position: 45 } ]
      @UI.identification: [ { position: 45 } ]
      @EndUserText.label: 'Spacesuit Color'
      SpacesuitColor,
      @UI.lineItem: [ { position: 55 } ]
      @UI.identification: [ { position: 55 } ]
      @EndUserText.label: 'Credits'
      Credits,
      /* Associations */
      _SpacedustCollection : redirected to composition child ZC_SD_COL
}
