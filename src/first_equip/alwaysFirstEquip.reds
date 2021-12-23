// --- CONFIG SECTION STARTS HERE

// -- Controls weapon firsEquip animation which 
//    usually appears when you equip any weapon for a first time
public class FirstEquipConfig {
  // Set the animation probability in percents, you can use values from 0 to 100 here
  // 0 means that animation never plays, 100 means that animation always plays
  public static func PercentageProbability() -> Int32 = 75
  // Replace false with true if you want see firstEquip animation while in combat mode
  public static func PlayInCombatMode() -> Bool = false
  // Replace false with true if you want see firstEquip animation while in stealth mode
  public static func PlayInStealthMode() -> Bool = false
  // Replace false with true if you want see firstEquip animation when weapon magazine is empty
  public static func PlayWhenMagazineIsEmpty() -> Bool = false
}

// -- Controls weapon IdleBreak animation which 
//    sometimes appears when V stands still with unsheathed weapon
public class IdleBreakConfig {
  // Replace true with false if you want to disable this feature and restore default weapon idle behavior
  public static func IsFeatureEnabled() -> Bool = true
  // Set the animation probability in percents, you can use values from 0 to 100 here
  // 0 means that animation never plays, 100 means that animation always plays
  public static func AnimationProbability() -> Int32 = 15
  // Animation checks period in seconds, each check decides if animation should be played 
  // based on probability value from AnimationProbability option
  public static func AnimationCheckPeriod() -> Float = 5.0
}

// --- CONFIG SECTION ENDS HERE, DO NOT EDIT ANYTHING BELOW


// -- Flag which controls if firstEquip animation must be skipped
@addField(PlayerPuppet)
let m_skipFirstEquip: Bool;

@addMethod(PlayerPuppet)
public func SetSkipFirstEquip_eq(skip: Bool) -> Void {
  this.m_skipFirstEquip = skip;
}

@addMethod(PlayerPuppet)
public func ShouldSkipFirstEquip_eq() -> Bool {
  return this.m_skipFirstEquip;
}

// -- Checks if firstEquip animation must be played depending on config 
@addMethod(PlayerPuppet)
public func ShouldRunFirstEquip_eq(weapon: wref<WeaponObject>) -> Bool {
  if WeaponObject.IsMagazineEmpty(weapon) && !FirstEquipConfig.PlayWhenMagazineIsEmpty() {
    return false;
  };

  if !FirstEquipConfig.PlayInCombatMode() && this.m_inCombat { return false; }
  if !FirstEquipConfig.PlayInStealthMode() && this.m_inCrouch { return false; }

  let probability: Int32 = FirstEquipConfig.PercentageProbability();
  let random: Int32 = RandRange(0, 100);

  if probability < 0 { return false; };
  if probability > 100 { return true; }

  return random <= probability;
}

// -- Checks if IdleBreak animation must be played depending on config 
@addMethod(PlayerPuppet)
public func ShouldRunIdleBreak_eq() -> Bool {
  let probability: Int32 = IdleBreakConfig.AnimationProbability();
  let random: Int32 = RandRange(0, 100);

  if probability < 0 { return false; };
  if probability > 100 { return true; }

  return random <= probability;
}

// -- Checks if player has any ranged weapon equipped
@addMethod(PlayerPuppet)
public func HasRangedWeaponEquipped_eq() -> Bool {
  let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.GetGame());
  let weapon: ref<WeaponObject> = transactionSystem.GetItemInSlot(this, t"AttachmentSlots.WeaponRight") as WeaponObject;
  if IsDefined(weapon) {
    if transactionSystem.HasTag(this, WeaponObject.GetRangedWeaponTag(), weapon.GetItemID()) {
      return true;
    };
  };
  return false;
}

// -- Handles skip flag for locomotion events
@replaceMethod(LocomotionEventsTransition)
public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let playerPuppet: ref<PlayerPuppet>;
  let event: Int32;
  let flag = UpperBodyTransition.HasRangedWeaponEquipped(scriptInterface);
  playerPuppet = scriptInterface.owner as PlayerPuppet;
  event = scriptInterface.localBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.LocomotionDetailed);
  if event == EnumInt(gamePSMDetailedLocomotionStates.Climb) || event == EnumInt(gamePSMDetailedLocomotionStates.Ladder) {
    if IsDefined(playerPuppet) {
      playerPuppet.SetSkipFirstEquip_eq(true);
    };
  };

  let blockAimingFor: Float = this.GetStaticFloatParameterDefault("softBlockAimingOnEnterFor", -1.00);
  if blockAimingFor > 0.00 {
    this.SoftBlockAimingForTime(stateContext, scriptInterface, blockAimingFor);
  };
  this.SetLocomotionParameters(stateContext, scriptInterface);
  this.SetCollisionFilter(scriptInterface);
  this.SetLocomotionCameraParameters(stateContext, scriptInterface);
}

// -- Handles skip flag for body carrying events
@replaceMethod(CarriedObjectEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let hasWeaponEquipped: Bool;
  let carrying: Bool = scriptInterface.localBlackboard.GetBool(GetAllBlackboardDefs().PlayerStateMachine.Carrying);
  let playerPuppet: ref<PlayerPuppet>;
  let attitude: EAIAttitude;
  let mountEvent: ref<MountingRequest>;
  let puppet: ref<gamePuppet>;
  let slotId: MountingSlotId;
  let workspotSystem: ref<WorkspotGameSystem>;
  let mountingInfo: MountingInfo = scriptInterface.GetMountingFacility().GetMountingInfoSingleWithObjects(scriptInterface.owner);
  let isNPCMounted: Bool = EntityID.IsDefined(mountingInfo.childId);
  // Set flag if player and not carrying yet
  playerPuppet = scriptInterface.executionOwner as PlayerPuppet;
  hasWeaponEquipped = playerPuppet.HasRangedWeaponEquipped_eq();
  if IsDefined(playerPuppet) && !carrying {
    playerPuppet.SetSkipFirstEquip_eq(hasWeaponEquipped);
  };
  if !isNPCMounted && !this.IsBodyDisposalOngoing(stateContext, scriptInterface) {
    mountEvent = new MountingRequest();
    slotId.id = n"leftShoulder";
    mountingInfo.childId = scriptInterface.ownerEntityID;
    mountingInfo.parentId = scriptInterface.executionOwnerEntityID;
    mountingInfo.slotId = slotId;
    mountEvent.lowLevelMountingInfo = mountingInfo;
    scriptInterface.GetMountingFacility().Mount(mountEvent);
    (scriptInterface.owner as NPCPuppet).MountingStartDisableComponents();
  };
  workspotSystem = scriptInterface.GetWorkspotSystem();
  this.m_animFeature = new AnimFeature_Mounting();
  this.m_animFeature.mountingState = 2;
  this.UpdateCarryStylePickUpAndDropParams(stateContext, scriptInterface, false);
  this.m_isFriendlyCarry = false;
  this.m_forcedCarryStyle = gamePSMBodyCarryingStyle.Any;
  puppet = scriptInterface.owner as gamePuppet;
  if IsDefined(puppet) {
    if IsDefined(workspotSystem) && !this.IsBodyDisposalOngoing(stateContext, scriptInterface) {
      workspotSystem.StopNpcInWorkspot(puppet);
    };
    attitude = GameObject.GetAttitudeBetween(scriptInterface.owner, scriptInterface.executionOwner);
    this.m_forcedCarryStyle = IntEnum(puppet.GetBlackboard().GetInt(GetAllBlackboardDefs().Puppet.ForcedCarryStyle));
    if Equals(this.m_forcedCarryStyle, gamePSMBodyCarryingStyle.Friendly) || Equals(attitude, EAIAttitude.AIA_Friendly) && Equals(this.m_forcedCarryStyle, gamePSMBodyCarryingStyle.Any) {
      this.m_isFriendlyCarry = true;
    };
    this.UpdateCarryStylePickUpAndDropParams(stateContext, scriptInterface, this.m_isFriendlyCarry);
  };
  scriptInterface.SetAnimationParameterFeature(n"Mounting", this.m_animFeature, scriptInterface.executionOwner);
  scriptInterface.SetAnimationParameterFeature(n"Mounting", this.m_animFeature);
  (scriptInterface.owner as NPCPuppet).MountingStartDisableComponents();
}

// -- Handles skip flag for interaction events
@replaceMethod(InteractiveDevice)
protected cb func OnInteractionUsed(evt: ref<InteractionChoiceEvent>) -> Bool {
  let playerPuppet: ref<PlayerPuppet>;
  let className: CName;
  let hasWeaponEquipped: Bool;
  // Set if player
  playerPuppet = evt.activator as PlayerPuppet;
  if IsDefined(playerPuppet) {
    className = evt.hotspot.GetClassName();
    if Equals(className, n"AccessPoint") || Equals(className, n"Computer") || Equals(className, n"Stillage") || Equals(className, n"WeakFence") {
      hasWeaponEquipped = playerPuppet.HasRangedWeaponEquipped_eq();
      playerPuppet.SetSkipFirstEquip_eq(hasWeaponEquipped);
    };
  };
  this.ExecuteAction(evt.choice, evt.activator, evt.layerData.tag);
}

// -- Handles skip flag for takedown events
@replaceMethod(gamestateMachineComponent)
protected cb func OnStartTakedownEvent(startTakedownEvent: ref<StartTakedownEvent>) -> Bool {
  let instanceData: StateMachineInstanceData;
  let initData: ref<LocomotionTakedownInitData> = new LocomotionTakedownInitData();
  let addEvent: ref<PSMAddOnDemandStateMachine> = new PSMAddOnDemandStateMachine();
  let record1HitDamage: ref<Record1DamageInHistoryEvent> = new Record1DamageInHistoryEvent();
  let playerPuppet: ref<PlayerPuppet>;
  initData.target = startTakedownEvent.target;
  initData.slideTime = startTakedownEvent.slideTime;
  initData.actionName = startTakedownEvent.actionName;
  instanceData.initData = initData;
  addEvent.stateMachineName = n"LocomotionTakedown";
  addEvent.instanceData = instanceData;
  let owner: wref<Entity> = this.GetEntity();
  owner.QueueEvent(addEvent);
  if IsDefined(startTakedownEvent.target) {
    record1HitDamage.source = owner as GameObject;
    startTakedownEvent.target.QueueEvent(record1HitDamage);
  };
  playerPuppet = owner as PlayerPuppet;
  if IsDefined(playerPuppet) {
    playerPuppet.SetSkipFirstEquip_eq(true);
  };
}

// -- Controls if firstEquip should be played
// -- Allows firstEquip in combat if PlayInCombatMode option enabled
@replaceMethod(EquipmentBaseTransition)
protected final const func HandleWeaponEquip(scriptInterface: ref<StateGameScriptInterface>, stateContext: ref<StateContext>, stateMachineInstanceData: StateMachineInstanceData, item: ItemID) -> Void {
  let statsEvent: ref<UpdateWeaponStatsEvent>;
  let weaponEquipEvent: ref<WeaponEquipEvent>;
  let animFeature: ref<AnimFeature_EquipUnequipItem> = new AnimFeature_EquipUnequipItem();
  let weaponEquipAnimFeature: ref<AnimFeature_EquipType> = new AnimFeature_EquipType();
  let transactionSystem: ref<TransactionSystem> = scriptInterface.GetTransactionSystem();
  let statSystem: ref<StatsSystem> = scriptInterface.GetStatsSystem();
  let mappedInstanceData: InstanceDataMappedToReferenceName = this.GetMappedInstanceData(stateMachineInstanceData.referenceName);
  let firstEqSystem: ref<FirstEquipSystem> = FirstEquipSystem.GetInstance(scriptInterface.owner);
  let itemObject: wref<WeaponObject> = transactionSystem.GetItemInSlot(scriptInterface.executionOwner, TDBID.Create(mappedInstanceData.attachmentSlot)) as WeaponObject;
  let isInCombat: Bool = scriptInterface.localBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Combat) == EnumInt(gamePSMCombat.InCombat);
  let playerPuppet: ref<PlayerPuppet> = scriptInterface.owner as PlayerPuppet;
  if TweakDBInterface.GetBool(t"player.weapon.enableWeaponBlur", false) {
    this.GetBlurParametersFromWeapon(scriptInterface);
  };

  // New logic
  if !isInCombat || FirstEquipConfig.PlayInCombatMode() {
    if IsDefined(playerPuppet) {
      if Equals(playerPuppet.ShouldSkipFirstEquip_eq(), true) {
        playerPuppet.SetSkipFirstEquip_eq(false);
      } else {
        if playerPuppet.ShouldRunFirstEquip_eq(itemObject) {
          weaponEquipAnimFeature.firstEquip = true;
          stateContext.SetConditionBoolParameter(n"firstEquip", true, true);
        };
      };
    };
  };

  // // Default game logic
  // if !isInCombat {
  //   if Equals(this.GetProcessedEquipmentManipulationRequest(stateMachineInstanceData, stateContext).equipAnim, gameEquipAnimationType.FirstEquip) || this.GetStaticBoolParameter("forceFirstEquip", false) || !firstEqSystem.HasPlayedFirstEquip(ItemID.GetTDBID(itemObject.GetItemID())) {
  //     weaponEquipAnimFeature.firstEquip = true;
  //     stateContext.SetConditionBoolParameter(n"firstEquip", true, true);
  //   };
  // };
  animFeature.stateTransitionDuration = statSystem.GetStatValue(Cast(itemObject.GetEntityID()), gamedataStatType.EquipDuration);
  animFeature.itemState = 1;
  animFeature.itemType = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(item)).ItemType().AnimFeatureIndex();
  this.BlockAimingForTime(stateContext, scriptInterface, animFeature.stateTransitionDuration + 0.10);
  weaponEquipAnimFeature.equipDuration = this.GetEquipDuration(scriptInterface, stateContext, stateMachineInstanceData);
  weaponEquipAnimFeature.unequipDuration = this.GetUnequipDuration(scriptInterface, stateContext, stateMachineInstanceData);
  scriptInterface.SetAnimationParameterFeature(mappedInstanceData.itemHandlingFeatureName, animFeature, scriptInterface.executionOwner);
  scriptInterface.SetAnimationParameterFeature(n"equipUnequipItem", animFeature, itemObject);
  weaponEquipEvent = new WeaponEquipEvent();
  weaponEquipEvent.animFeature = weaponEquipAnimFeature;
  weaponEquipEvent.item = itemObject;
  GameInstance.GetDelaySystem(scriptInterface.executionOwner.GetGame()).DelayEvent(scriptInterface.executionOwner, weaponEquipEvent, 0.03);
  scriptInterface.executionOwner.QueueEventForEntityID(itemObject.GetEntityID(), new PlayerWeaponSetupEvent());
  statsEvent = new UpdateWeaponStatsEvent();
  scriptInterface.executionOwner.QueueEventForEntityID(itemObject.GetEntityID(), statsEvent);
  if weaponEquipAnimFeature.firstEquip {
    scriptInterface.SetAnimationParameterFloat(n"safe", 0.00);
    stateContext.SetPermanentBoolParameter(n"WeaponInSafe", false, true);
    stateContext.SetPermanentFloatParameter(n"TurnOffPublicSafeTimeStamp", EngineTime.ToFloat(GameInstance.GetSimTime(scriptInterface.owner.GetGame())), true);
  } else {
    if stateContext.GetBoolParameter(n"InPublicZone", true) {
    } else {
      if stateContext.GetBoolParameter(n"WeaponInSafe", true) {
        scriptInterface.SetAnimationParameterFloat(n"safe", 1.00);
      };
    };
  };
}


// -- IdleBreak animation

// -- Timestamp field to control the mod logic periods
@addField(ReadyEvents)
private let m_savedIdleTimestamp: Float;

// -- Set initial m_savedIdleTimestamp value
@wrapMethod(ReadyEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  this.m_savedIdleTimestamp = this.m_timeStamp;
}

// -- Checks if AnimationCheckPeriod passed and IdleBreak must be triggered
@replaceMethod(ReadyEvents)
protected final func OnTick(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let animFeature: ref<AnimFeature_WeaponHandlingStats>;
  let ownerID: EntityID;
  let statsSystem: ref<StatsSystem>;
  let gameInstance: GameInstance = scriptInterface.GetGame();
  let currentTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gameInstance));
  let behindCover: Bool = NotEquals(GameInstance.GetSpatialQueriesSystem(gameInstance).GetPlayerObstacleSystem().GetCoverDirection(scriptInterface.executionOwner), IntEnum(0l));
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  let playerStandsStill: Bool;
  let timePassed: Bool;

  if behindCover {
    this.m_timeStamp = currentTime;
    stateContext.SetPermanentFloatParameter(n"TurnOffPublicSafeTimeStamp", this.m_timeStamp, true);
  };
  // New logic
  if IdleBreakConfig.IsFeatureEnabled() {
    if IsDefined(player) {
      playerStandsStill = WeaponTransition.GetPlayerSpeed(scriptInterface) < 0.10 && stateContext.IsStateActive(n"Locomotion", n"stand");
      timePassed = currentTime - this.m_savedIdleTimestamp > IdleBreakConfig.AnimationCheckPeriod();
      if timePassed && playerStandsStill {
        this.m_savedIdleTimestamp = currentTime;
        if player.ShouldRunIdleBreak_eq() {
          scriptInterface.PushAnimationEvent(n"IdleBreak");
        };
      };
    };
  } else {
    // Default game logic
    if WeaponTransition.GetPlayerSpeed(scriptInterface) < 0.10 && stateContext.IsStateActive(n"Locomotion", n"stand") {
      if scriptInterface.localBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Combat) != EnumInt(gamePSMCombat.InCombat) && !behindCover {
        if this.m_timeStamp + this.GetStaticFloatParameterDefault("timeBetweenIdleBreaks", 20.00) <= currentTime {
          scriptInterface.PushAnimationEvent(n"IdleBreak");
          this.m_timeStamp = currentTime;
        };
      };
    };
  };

  if this.IsHeavyWeaponEmpty(scriptInterface) && !stateContext.GetBoolParameter(n"requestHeavyWeaponUnequip", true) {
    stateContext.SetPermanentBoolParameter(n"requestHeavyWeaponUnequip", true, true);
  };
  statsSystem = GameInstance.GetStatsSystem(gameInstance);
  ownerID = scriptInterface.ownerEntityID;
  animFeature = new AnimFeature_WeaponHandlingStats();
  animFeature.weaponRecoil = statsSystem.GetStatValue(Cast(ownerID), gamedataStatType.RecoilAnimation);
  animFeature.weaponSpread = statsSystem.GetStatValue(Cast(ownerID), gamedataStatType.SpreadAnimation);
  scriptInterface.SetAnimationParameterFeature(n"WeaponHandlingData", animFeature, scriptInterface.executionOwner);
}
