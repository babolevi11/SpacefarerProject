@EndUserText.label: 'Stardust Transaction Ledger Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true // Allows adding UI layout annotations later
define root view entity ZC_STARDUST_LEDGER
  provider contract transactional_query
  as projection on ZR_STARDUST_LEDGER
{
  key TransactionId,
      StardustId,
      FromSpacefarerId,
      FromSpacefarerName,
      ToSpacefarerId,
      ToSpacefarerName,
      TradeType,
      PriceInCredits,
      ExchangeType,
      CreatedAt,

      /* Redirect back to the projected parent */
      _Stardust,
      _ToSpacefarer,
      _FromSpacefarer
}
