@EndUserText.label: 'Stardust Buyer Purchase Input Form'
define abstract entity ZA_BUYER_PARAM
{
//  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_SPACEF', element: 'SpacefarerName' } }]
//  @EndUserText.label: 'Select Purchasing Spacefarer'
//  buyer_spacefarer_name : char72;
   /* This field is hidden from the user but gets filled in the background */
  @UI.hidden: true
  BuyerSpacefarerId   : sysuuid_x16;

  /* The user interacts with this field. The value help maps both fields on selection */
  @Consumption.valueHelpDefinition: [{ 
      entity: { name: 'ZR_SPACEF', element: 'SpacefarerName' },
      additionalBinding: [{ 
        element: 'SpacefarerId',               // The field name inside ZR_SPACEF
        localElement: 'BuyerSpacefarerId',   // Maps it back to the hidden ID parameter field
        usage: #RESULT                         // Tells the UI to return the result value
      }]
  }]
  @EndUserText.label: 'Select Purchasing Spacefarer Name'
  BuyerSpacefarerName   : char72;
}
