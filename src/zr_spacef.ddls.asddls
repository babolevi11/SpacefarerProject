@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Data Modell View for ZBL0923_T_SPACEF'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zr_spacef
  as select from zbl0923_t_spacef
  composition [0..*] of ZR_sd_col               as _SpacedustCollection
  association [0..1] to ZI_NAVIGATION_SKILLS_VH as _NavigationSkillsText on $projection.NavigationSkill = _NavigationSkillsText.NavigationSkill
{
  key spacefarer_id    as SpacefarerId,
      spacefarer_name  as SpacefarerName,
      @ObjectModel.text.association: '_NavigationSkillsText'
      navigation_skill as NavigationSkill,
      reputation       as Reputation,
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_PLANET_SUITCOLOR', element: 'Planet' }
      }]
      origin_planet    as OriginPlanet,
      spacesuit_color  as SpacesuitColor,
      credits          as Credits,
      last_changed_at  as LastChangedAt,


      _SpacedustCollection,
      _NavigationSkillsText
}
