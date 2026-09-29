@AbapCatalog.viewEnhancementCategory: [#NONE]
//@AccessControl.authorizationCheck: #NOT_REQUIRED
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Stardust Transaction Ledger Interface'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_STARDUST_LEDGER
  as select from zbl0923_t_tr_gl as Ledger

  /* 1. Association to the Stardust Asset itself */
//  association        to parent ZR_SD_COL as _Stardust       on $projection.StardustId = _Stardust.ItemId
  association [1..1] to ZR_SD_COL as _Stardust on $projection.StardustId = _Stardust.ItemId
  /* 2. Associations to look up the trading parties */
  association [1..1] to zr_spacef        as _FromSpacefarer on $projection.FromSpacefarerId = _FromSpacefarer.SpacefarerId
  association [1..1] to zr_spacef        as _ToSpacefarer   on $projection.ToSpacefarerId = _ToSpacefarer.SpacefarerId
{
  key transaction_id                 as TransactionId,
      stardust_id                    as StardustId,
      from_spacefarer_id             as FromSpacefarerId,
      from_spacefarer_name as FromSpacefarerName,
//      @ObjectModel.text.association: '_MatterText'
      state_of_matter               as StateOfMatter,
      color_of_dust                 as ColorOfDust,
      @Semantics.quantity.unitOfMeasure : 'WeightUnit'
      weight                        as Weight,
      weight_unit                as WeightUnit,
      to_spacefarer_id               as ToSpacefarerId,
      to_spacefarer_name   as ToSpacefarerName,
      trade_type                     as TradeType,
      price_in_credits               as PriceInCredits,
      exchange_type                  as ExchangeType,
      created_at                     as CreatedAt,
      last_changed_at                as LastChangedAt,

      /* Expose the associations for navigation path usage */
      _Stardust,
      _FromSpacefarer,
      _ToSpacefarer
}
