@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view for Spacdust Collection'
//@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_SD_COL as projection on ZR_SD_COL
{
    key ItemId,
    SpacefarerId,
    SpacefarerName,
    StateOfMatter,
    ColorOfDust,
    @Semantics.quantity.unitOfMeasure : 'WeightUnit'
    Weight,
    WeightUnit,
    Value,
    IsForSale,
    ExchangeStatus,
    OfferedToId,
    OfferedToName,
    OfferedInExchangedFor,

    _Spacefarer : redirected to parent ZC_SPACEF,
    _TradeLedger,
    _DustColorVH
}
