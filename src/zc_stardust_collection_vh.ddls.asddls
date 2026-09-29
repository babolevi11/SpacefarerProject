//@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value help for stardust collection'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZC_STARDUST_COLLECTION_VH
  as select from ZR_SD_COL
{
      @ObjectModel.text.element: ['ItemId']
  key ItemId,
      SpacefarerName,
      StateOfMatter,
      ColorOfDust,
      Value
}
where ExchangeStatus != 'PROPOSED' or ExchangeStatus != 'INCOMING'
