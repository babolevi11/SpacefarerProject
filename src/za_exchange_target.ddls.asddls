@EndUserText.label: 'Exchange Target Parameter'
define abstract entity ZA_EXCHANGE_TARGET
{
  //  @Consumption.valueHelpDefinition: [{
  //      entity: { name: 'ZR_SD_COL', element: 'ItemId' },
  //      additionalBinding: [{
  //        element: 'ItemId',               // The field name inside ZR_SPACEF
  //        localElement: 'OfferedInExchangedForId',   // Maps it back to the hidden ID parameter field
  //        usage: #RESULT                         // Tells the UI to return the result value
  //      }]
  //  }]
  //  @EndUserText.label: 'Offerer for Stardust'

  //  @UI.hidden: true
  //  OfferedToId             : sysuuid_x16;
  //  @Consumption.valueHelpDefinition: [{
  //      entity: { name: 'ZR_SPACEF', element: 'SpacefarerName' },
  //      additionalBinding: [{
  //        element: 'SpacefarerId',               // The field name inside ZR_SPACEF
  //        localElement: 'OfferedToId',   // Maps it back to the hidden ID parameter field
  //        usage: #RESULT                         // Tells the UI to return the result value
  //      }]
  //  }]
  //  @EndUserText.label: 'Offerer to Spacefarer'
  //  OfferedToName           : char72;
  //
  //  @Consumption.valueHelpDefinition: [{
  //      entity: { name: 'ZR_SD_COL', element: 'ItemId' } // Value help binds directly to the active field
  //  }]
  //  @EndUserText.label: 'Offered In Exchanged For Item'
  //  OfferedInExchangedForId : sysuuid_x16;

  //  @Consumption.valueHelpDefinition: [{
  //        entity            : { name: 'ZR_SD_COL', element: 'ItemId' }
  //    }]
  //  @EndUserText.label      : 'Item Desired in Return'

  @EndUserText.label      : 'Select Offered For'
  @Consumption.valueHelpDefinition: [{
    entity                : { name: 'ZC_STARDUST_COLLECTION_VH', element: 'ItemId' }
  }]
  OfferedInExchangedForId : sysuuid_x16;
}
