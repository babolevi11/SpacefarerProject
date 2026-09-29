@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Data Modelling View for ZBL0923_T_SD_COL'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_SD_COL
  as select from zbl0923_t_sd_col
  association        to parent zr_spacef      as _Spacefarer  on $projection.SpacefarerId = _Spacefarer.SpacefarerId
  association [0..1] to ZI_STATE_OF_MATTER_VH as _MatterText  on $projection.StateOfMatter = _MatterText.StateOfMatterCode
  association [0..*] to ZI_DUST_COLOR_VH      as _DustColorVH on $projection.ColorOfDust = _DustColorVH.DustColor
  association [1..*] to ZR_STARDUST_LEDGER    as _TradeLedger on $projection.ItemId = _TradeLedger.TransactionId

{
  key item_id                       as ItemId,
      spacefarer_id                 as SpacefarerId,
      _Spacefarer.SpacefarerName    as SpacefarerName,
      @ObjectModel.text.association: '_MatterText'
      state_of_matter               as StateOfMatter,
      color_of_dust                 as ColorOfDust,
      @Semantics.quantity.unitOfMeasure : 'WeightUnit'
      weight                        as Weight,
      cast( 'G' as abap.unit( 3 ) ) as WeightUnit,
      //      @Semantics.unitOfMeasure: true
      //      weight_unit                as WeightUnit,
      value                         as Value,
      is_for_sale                   as IsForSale,
      exchange_status               as ExchangeStatus,
      offered_to_id                 as OfferedToId,
      offered_to_name               as OfferedToName,
      offered_in_exch_for           as OfferedInExchangedFor,

      _Spacefarer,
      _MatterText,
      _DustColorVH,
      _TradeLedger
}
