import LimitedHudConfig.QuestTrackerModuleConfig
import LimitedHudCommon.LHUDEventType
import LimitedHudCommon.LHUDEvent

@addMethod(QuestTrackerGameController)
protected cb func OnLHUDEvent(evt: ref<LHUDEvent>) -> Void {
  this.ConsumeLHUDEvent(evt);
  this.DetermineCurrentVisibility();
}

@addMethod(QuestTrackerGameController)
public func DetermineCurrentVisibility() -> Void {
  if !QuestTrackerModuleConfig.IsEnabled() {
    return ;
  };

  if this.lhud_isBraindanceActive {
    this.lhud_isVisibleNow = true;
    this.AnimateAlphaLHUD(this.GetRootWidget(), 1.0, 0.3);
    return ;
  };

  let showForGlobalHotkey: Bool = this.lhud_isGlobalFlagToggled && QuestTrackerModuleConfig.BindToGlobalHotkey();
  let showForCombat: Bool = this.lhud_isCombatActive && QuestTrackerModuleConfig.ShowInCombat();
  let showForOutOfCombat: Bool = this.lhud_isOutOfCombatActive && QuestTrackerModuleConfig.ShowOutOfCombat();
  let showForStealth: Bool =  this.lhud_isStealthActive && QuestTrackerModuleConfig.ShowInStealth();
  let showForVehicle: Bool =  this.lhud_isInVehicle && QuestTrackerModuleConfig.ShowInVehicle();
  let showForScanner: Bool =  this.lhud_isScannerActive && QuestTrackerModuleConfig.ShowWithScanner();
  let showForWeapon: Bool = this.lhud_isWeaponUnsheathed && QuestTrackerModuleConfig.ShowWithWeapon();
  let showForZoom: Bool =  this.lhud_isZoomActive && QuestTrackerModuleConfig.ShowWithZoom();

  let isVisible: Bool = showForGlobalHotkey || showForCombat || showForOutOfCombat || showForStealth || showForVehicle || showForScanner || showForWeapon || showForZoom;
  if NotEquals(this.lhud_isVisibleNow, isVisible) {
    this.lhud_isVisibleNow = isVisible;
    if isVisible {
      this.AnimateAlphaLHUD(this.GetRootWidget(), 1.0, 0.3);
    } else {
      this.AnimateAlphaLHUD(this.GetRootWidget(), 0.0, 0.3);
    };
  };
}

@wrapMethod(QuestTrackerGameController)
protected cb func OnInitialize() -> Bool {
  wrappedMethod();
  if QuestTrackerModuleConfig.IsEnabled() {
    this.lhud_isVisibleNow = false;
    this.GetRootWidget().SetOpacity(0.0);
    this.OnInitializeFinished();
  };
}

// -- Temporarily show tracker and then schedule hiding
@wrapMethod(QuestTrackerGameController)
protected cb func OnTrackedEntryChanges(hash: Uint32, className: CName, notifyOption: JournalNotifyOption, changeType: JournalChangeType) -> Bool {
  wrappedMethod(hash, className, notifyOption, changeType);

  let callback: ref<LHUDHideQuestTrackerCallback>;
  if QuestTrackerModuleConfig.IsEnabled() && QuestTrackerModuleConfig.DisplayForQuestUpdates() {
    // Show tracker
    this.lhud_isVisibleNow = true;
    this.AnimateAlphaLHUD(this.GetRootWidget(), 1.0, 0.3);
    // Schedule hiding
    callback = new LHUDHideQuestTrackerCallback();
    callback.uiSystem = GameInstance.GetUISystem(this.GetPlayerControlledObject().GetGame());
    GameInstance.GetDelaySystem(this.GetPlayerControlledObject().GetGame()).DelayCallback(callback, QuestTrackerModuleConfig.QuestUpdateDisplayingTime());
  };
}

public class LHUDHideQuestTrackerCallback extends DelayCallback {
  public let uiSystem: wref<UISystem>;
  public func Call() -> Void {
    let evt: ref<LHUDEvent> = new LHUDEvent();
    evt.type = LHUDEventType.Refresh;
    evt.isActive = false;
    this.uiSystem.QueueEvent(evt);
  }
}
