@EndUserText.label: 'Exchange Target Parameter'
define abstract entity ZA_EXCHANGE_TARGET
{
  @EndUserText.label      : 'Select Offered For'
  @Consumption.valueHelpDefinition: [{
    entity                : { name: 'ZC_STARDUST_COLLECTION_VH', element: 'ItemId' }
  }]
  OfferedInExchangedForId : sysuuid_x16;
}
