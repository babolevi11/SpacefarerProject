@EndUserText.label: 'Parameters for Offer acceptance or rejection'
define abstract entity za_accept_reject_offer
{
    @EndUserText.label      : 'Select Offered For'
  @Consumption.valueHelpDefinition: [{
    entity                : { name: 'zi_accep_reject_vh', element: 'StatusValue' }
  }]
  AcceptReject            : zde_accep_reject;
}
