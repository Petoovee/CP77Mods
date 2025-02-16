@replaceMethod(InventoryDataManagerV2)
public final func IsTransmogEnabled() -> Int32 {
  return 1;
}

@addMethod(InventoryItemDisplayController)
public func ShouldDisplayControl(area: gamedataEquipmentArea) -> Bool {
  return
    Equals(area, gamedataEquipmentArea.Head) || 
    Equals(area, gamedataEquipmentArea.Face) ||
    Equals(area, gamedataEquipmentArea.Feet) || 
    Equals(area, gamedataEquipmentArea.Legs) || 
    Equals(area, gamedataEquipmentArea.InnerChest) || 
    Equals(area, gamedataEquipmentArea.OuterChest) || 
  false;
}

@replaceMethod(InventoryItemDisplayController)
private final func UpdateTransmogControls(isEmpty: Bool) -> Void {
  let isItemHidden: Bool;
  let showControl: Bool = this.ShouldDisplayControl(this.m_equipmentArea) && !this.m_isLocked;
  if !inkWidgetRef.IsValid(this.m_transmogContainer) {
    return;
  };
  if !isEmpty && showControl {
    if !IsDefined(this.m_btnHideAppearance) {
      this.m_btnHideAppearance = this.SpawnFromLocal(inkWidgetRef.Get(this.m_transmogContainer), n"hideButton");
      this.m_btnHideAppearanceCtrl = this.m_btnHideAppearance.GetControllerByType(n"TransmogButtonView") as TransmogButtonView;
    };
    isItemHidden = this.m_inventoryDataManager.IsSlotHidden(this.m_equipmentArea);
    this.m_btnHideAppearanceCtrl.SetActive(!isItemHidden);
  } else {
    if IsDefined(this.m_btnHideAppearance) {
      inkCompoundRef.RemoveAllChildren(this.m_transmogContainer);
      this.m_btnHideAppearance = null;
      this.m_btnHideAppearanceCtrl = null;
    };
  };
  if !isEmpty && this.m_inventoryDataManager.IsSlotOverriden(this.m_equipmentArea) {
    this.m_transmogItem = this.m_inventoryDataManager.GetVisualItemInSlot(this.m_equipmentArea);
  } else {
    this.m_transmogItem = ItemID.FromTDBID(t"");
  };
}

@replaceMethod(InventoryDataManagerV2)
public final func ToggleItemVisibility(area: gamedataEquipmentArea) -> Void {
  this.m_EquipmentSystem.GetPlayerData(this.m_Player).ToggleSlotVisibilityCustom(area);
}

@replaceMethod(InventoryDataManagerV2)
public final func IsSlotHidden(area: gamedataEquipmentArea) -> Bool {
  return this.m_EquipmentSystem.GetPlayerData(this.m_Player).IsSlotHiddenCustom(area);
}


// -- [EquipmentSystemPlayerData]

@addField(EquipmentSystemPlayerData) private persistent let m_headToggleHG: Bool;
@addField(EquipmentSystemPlayerData) private persistent let m_faceToggleHG: Bool;
@addField(EquipmentSystemPlayerData) private persistent let m_feetToggleHG: Bool;
@addField(EquipmentSystemPlayerData) private persistent let m_legsToggleHG: Bool;
@addField(EquipmentSystemPlayerData) private persistent let m_innerChestToggleHG: Bool;
@addField(EquipmentSystemPlayerData) private persistent let m_outerChestToggleHG: Bool;

@addMethod(EquipmentSystemPlayerData)
public func ToggleSlotVisibilityCustom(area: gamedataEquipmentArea) -> Void {
  switch (area) {
    case gamedataEquipmentArea.Head:
      this.SetHeadSlotToggleHG(!this.m_headToggleHG);
      break;
    case gamedataEquipmentArea.Face:
      this.SetFaceSlotToggleHG(!this.m_faceToggleHG);
      break;
    case gamedataEquipmentArea.Feet:
      this.SetFeetSlotToggleHG(!this.m_feetToggleHG);
      break;
    case gamedataEquipmentArea.Legs:
      this.SetLegsSlotToggleHG(!this.m_legsToggleHG);
      break;
    case gamedataEquipmentArea.InnerChest:
      this.SetInnerChestSlotToggleHG(!this.m_innerChestToggleHG);
      break;
    case gamedataEquipmentArea.OuterChest:
      this.SetOuterChestSlotToggleHG(!this.m_outerChestToggleHG);
      break;
    default:
      break;
  };
}

@addMethod(EquipmentSystemPlayerData)
public func IsSlotHiddenCustom(area: gamedataEquipmentArea) -> Bool {
  let notCensored: Bool = this.IsBuildCensored();
  let showGenitals: Bool = this.ShouldShowGenitals();
  switch (area) {
    case gamedataEquipmentArea.Head: return this.m_headToggleHG;
    case gamedataEquipmentArea.Face: return this.m_faceToggleHG;
    case gamedataEquipmentArea.Feet: return this.m_feetToggleHG;
    case gamedataEquipmentArea.Legs: return this.m_legsToggleHG;
    case gamedataEquipmentArea.InnerChest: return this.m_innerChestToggleHG;
    case gamedataEquipmentArea.OuterChest: return this.m_outerChestToggleHG;
    case gamedataEquipmentArea.UnderwearBottom: return notCensored && showGenitals;
    case gamedataEquipmentArea.UnderwearTop: return notCensored;
    default: return false;
  };
}

@addMethod(EquipmentSystemPlayerData)
private func ResetItemVisibility(area: gamedataEquipmentArea) {
  this.ResetItemAppearanceEvent(area);
}

@addMethod(EquipmentSystemPlayerData)
private func ToggleItemVisibility(area: gamedataEquipmentArea, shouldHide: Bool) {
  let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  if shouldHide {
    if Equals(area, gamedataEquipmentArea.Legs) {
      this.ClearItemAppearance(transactionSystem, area);
    } else {
      this.ClearItemAppearanceEvent(area);
    };
  } else {
    this.ResetItemAppearanceEvent(area);
  };

  this.ResetItemAppearanceEvent(gamedataEquipmentArea.UnderwearBottom);
}

@addMethod(EquipmentSystemPlayerData)
private func SetHeadSlotToggleHG(visible: Bool) -> Void {
  this.m_headToggleHG = visible;
  this.ToggleItemVisibility(gamedataEquipmentArea.Head, this.m_headToggleHG);
}

@addMethod(EquipmentSystemPlayerData)
private func SetFaceSlotToggleHG(visible: Bool) -> Void {
  this.m_faceToggleHG = visible;
  this.ToggleItemVisibility(gamedataEquipmentArea.Face, this.m_faceToggleHG);
}

@addMethod(EquipmentSystemPlayerData)
private func SetFeetSlotToggleHG(visible: Bool) -> Void {
  this.m_feetToggleHG = visible;
  this.ToggleItemVisibility(gamedataEquipmentArea.Feet, this.m_feetToggleHG);
}

@addMethod(EquipmentSystemPlayerData)
private func SetLegsSlotToggleHG(visible: Bool) -> Void {
  this.m_legsToggleHG = visible;
  this.ToggleItemVisibility(gamedataEquipmentArea.Legs, this.m_legsToggleHG);
}

@addMethod(EquipmentSystemPlayerData)
private func SetInnerChestSlotToggleHG(visible: Bool) -> Void {
  this.m_innerChestToggleHG = visible;
  this.ToggleItemVisibility(gamedataEquipmentArea.InnerChest, this.m_innerChestToggleHG);
}

@addMethod(EquipmentSystemPlayerData)
private func SetOuterChestSlotToggleHG(visible: Bool) -> Void {
  this.m_outerChestToggleHG = visible;
  this.ToggleItemVisibility(gamedataEquipmentArea.OuterChest, this.m_outerChestToggleHG);
}

// Hide underwear after the game loaded
public class EvaluateSlotsVisibilityCallback extends DelayCallback {
  public let playerData: wref<EquipmentSystemPlayerData>;

  public func Call() -> Void {
    this.playerData.ResetItemVisibility(gamedataEquipmentArea.Head);
    this.playerData.ResetItemVisibility(gamedataEquipmentArea.Face);
    this.playerData.ResetItemVisibility(gamedataEquipmentArea.Feet);
    this.playerData.ResetItemVisibility(gamedataEquipmentArea.Legs);
    this.playerData.ResetItemVisibility(gamedataEquipmentArea.InnerChest);
    this.playerData.ResetItemVisibility(gamedataEquipmentArea.OuterChest);

    this.playerData.ToggleItemVisibility(gamedataEquipmentArea.Head, this.playerData.IsSlotHiddenCustom(gamedataEquipmentArea.Head));
    this.playerData.ToggleItemVisibility(gamedataEquipmentArea.Face, this.playerData.IsSlotHiddenCustom(gamedataEquipmentArea.Face));
    this.playerData.ToggleItemVisibility(gamedataEquipmentArea.Feet, this.playerData.IsSlotHiddenCustom(gamedataEquipmentArea.Feet));
    this.playerData.ToggleItemVisibility(gamedataEquipmentArea.Legs, this.playerData.IsSlotHiddenCustom(gamedataEquipmentArea.Legs));
    this.playerData.ToggleItemVisibility(gamedataEquipmentArea.InnerChest, this.playerData.IsSlotHiddenCustom(gamedataEquipmentArea.InnerChest));
    this.playerData.ToggleItemVisibility(gamedataEquipmentArea.OuterChest, this.playerData.IsSlotHiddenCustom(gamedataEquipmentArea.OuterChest));

    // LogChannel(n"DEBUG", "Hide Head Gear: slots refreshed...");
  }
}

@addField(EquipmentSystemPlayerData)
public let m_slotsRefreshDelayId: DelayID;

@addMethod(EquipmentSystemPlayerData)
public func ScheduleSlotsVisibilityRefresh(delay: Float) -> Void {
  let callback: ref<EvaluateSlotsVisibilityCallback> = new EvaluateSlotsVisibilityCallback();
  callback.playerData = this;
  GameInstance.GetDelaySystem(this.m_owner.GetGame()).CancelDelay(this.m_slotsRefreshDelayId);
  this.m_slotsRefreshDelayId = GameInstance.GetDelaySystem(this.m_owner.GetGame()).DelayCallback(callback, delay);
}

// Photomode tweaks

@replaceMethod(PhotoModePlayerEntityComponent)
private final func PutOnFakeItem(itemToAdd: ItemID, puppet: wref<PlayerPuppet>) -> Void {
  let item: ItemID;
  let itemData: wref<gameItemData>;
  let equipAreaType: gamedataEquipmentArea = EquipmentSystem.GetEquipAreaType(itemToAdd);
  let currSlot: TweakDBID = EquipmentSystem.GetPlacementSlot(itemToAdd);
  if EquipmentSystem.GetData(puppet).IsSlotHiddenCustom(equipAreaType) {
    return;
  };
  if Equals(equipAreaType, gamedataEquipmentArea.RightArm) {
    item = ItemID.FromTDBID(ItemID.GetTDBID(itemToAdd));
    this.TS.GiveItem(this.fakePuppet, item, 1);
  } else {
    itemData = this.TS.GetItemData(puppet, itemToAdd);
    item = itemData.GetID();
    this.TS.GivePreviewItemByItemData(this.fakePuppet, itemData);
  };
  if this.TS.CanPlaceItemInSlot(this.fakePuppet, currSlot, item) && this.TS.AddItemToSlot(this.fakePuppet, currSlot, item, true) {
    if this.TS.HasItemInSlot(puppet, currSlot, itemToAdd) {
      ArrayPush(this.loadingItems, item);
    };
    this.itemsLoadingTime = EngineTime.ToFloat(this.GetEngineTime());
  };
}

// Game loaded
@wrapMethod(PlayerPuppet)
protected cb func OnMakePlayerVisibleAfterSpawn(evt: ref<EndGracePeriodAfterSpawn>) -> Bool {
  wrappedMethod(evt);
  EquipmentSystem.GetData(this).ScheduleSlotsVisibilityRefresh(1.0);
}


// Slept or showered
@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  wrappedMethod(evt);
  if Equals(evt.staticData.StatusEffectType().Type(), gamedataStatusEffectType.Housing) {
    EquipmentSystem.GetData(this).ScheduleSlotsVisibilityRefresh(4.0);
  };
}

@addMethod(EquipmentSystemPlayerData)
private func ResetAllTogglesHG() -> Void {
  this.SetHeadSlotToggleHG(false);
  this.SetFaceSlotToggleHG(false);
  this.SetFeetSlotToggleHG(false);
  this.SetLegsSlotToggleHG(false);
  this.SetInnerChestSlotToggleHG(false);
  this.SetOuterChestSlotToggleHG(false);
}

@wrapMethod(EquipmentSystemPlayerData)
private final func EquipItem(itemID: ItemID, slotIndex: Int32, opt blockActiveSlotsUpdate: Bool, opt forceEquipWeapon: Bool) -> Void {
  let data: wref<gameItemData> = RPGManager.GetItemData(this.m_owner.GetGame(), this.m_owner, itemID);
  if !this.IsEquippable(data) {
    return;
  };
  let index: Int32 = this.GetEquipAreaIndex(EquipmentSystem.GetEquipAreaType(itemID));
  let area: SEquipArea = this.m_equipment.equipAreas[index];

  // Reset all toggles on Outfit slot equip
  if Equals(area.areaType, gamedataEquipmentArea.Outfit) {
    this.ResetAllTogglesHG();
  };

  wrappedMethod(itemID, slotIndex, blockActiveSlotsUpdate, forceEquipWeapon);
}
