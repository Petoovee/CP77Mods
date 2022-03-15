import LimitedHudConfig.LHUDAddonsConfig

@wrapMethod(JournalNotification)
protected cb func OnInitialize() -> Bool {
  wrappedMethod();
  let scale: Float = LHUDAddonsConfig.JournalNotificationScale();
  let opacity: Float = LHUDAddonsConfig.JournalNotificationOpacity();
  this.GetRootWidget().SetScale(new Vector2(scale, scale)); // Scale
  this.GetRootWidget().SetOpacity(opacity);                 // Opacity
}

// SOUNDS

@replaceMethod(JournalNotificationQueue)
private final func PushObjectiveQuestNotification(entry: wref<JournalEntry>) -> Void {
  let notificationData: gameuiGenericNotificationData;
  let parentQuestEntry: wref<JournalQuest>;
  let questAction: ref<TrackQuestNotificationAction>;
  let userData: ref<QuestUpdateNotificationViewData>;
  let currentEntry: wref<JournalEntry> = entry;
  while parentQuestEntry == null {
    currentEntry = this.m_journalMgr.GetParentEntry(currentEntry);
    if !IsDefined(currentEntry) {
      return;
    };
    parentQuestEntry = currentEntry as JournalQuest;
  };
  userData = new QuestUpdateNotificationViewData();
  userData.questEntryId = parentQuestEntry.GetId();
  userData.entryHash = this.m_journalMgr.GetEntryHash(parentQuestEntry);
  userData.text = parentQuestEntry.GetTitle(this.m_journalMgr);
  userData.title = "UI-Notifications-QuestUpdated";
  if !LHUDAddonsConfig.JournalNotificationDisableQuestCurrent() {
    userData.soundEvent = n"QuestUpdatePopup";
  };
  userData.soundAction = n"OnOpen";
  userData.animation = n"notification_quest_updated";
  userData.canBeMerged = true;
  questAction = new TrackQuestNotificationAction();
  questAction.m_questEntry = parentQuestEntry;
  questAction.m_journalMgr = this.m_journalMgr;
  userData.action = questAction;
  notificationData.time = this.m_showDuration;
  notificationData.widgetLibraryItemName = n"notification_quest_updated";
  notificationData.notificationData = userData;
  this.AddNewNotificationData(notificationData);
}

@replaceMethod(JournalNotificationQueue)
private final func PushQuestNotification(questEntry: wref<JournalQuest>, state: gameJournalEntryState) -> Void {
  let notificationData: gameuiGenericNotificationData;
  let questAction: ref<TrackQuestNotificationAction>;
  let userData: ref<QuestUpdateNotificationViewData> = new QuestUpdateNotificationViewData();
  userData.entryHash = this.m_journalMgr.GetEntryHash(questEntry);
  userData.questEntryId = questEntry.GetId();
  userData.text = questEntry.GetTitle(this.m_journalMgr);
  userData.canBeMerged = false;
  switch state {
    case gameJournalEntryState.Active:
      userData.title = "UI-Notifications-NewQuest";
      questAction = new TrackQuestNotificationAction();
      questAction.m_questEntry = questEntry;
      questAction.m_journalMgr = this.m_journalMgr;
      userData.action = questAction;
      if !LHUDAddonsConfig.JournalNotificationDisableQuestCore() {
        userData.soundEvent = n"QuestNewPopup";
      };
      userData.soundAction = n"OnOpen";
      userData.animation = n"notification_new_quest_added";
      notificationData.time = this.m_showDuration;
      notificationData.widgetLibraryItemName = n"notification_new_quest_added";
      notificationData.notificationData = userData;
      this.AddNewNotificationData(notificationData);
      break;
    case gameJournalEntryState.Succeeded:
      userData.title = "UI-Notifications-QuestCompleted";
      if !LHUDAddonsConfig.JournalNotificationDisableQuestCore() {
        userData.soundEvent = n"QuestSuccessPopup";
      };
      userData.soundAction = n"OnOpen";
      userData.animation = n"notification_quest_completed";
      userData.dontRemoveOnRequest = true;
      notificationData.time = 12.00;
      notificationData.widgetLibraryItemName = n"notification_quest_completed";
      notificationData.notificationData = userData;
      this.AddNewNotificationData(notificationData);
      break;
    case gameJournalEntryState.Failed:
      userData.title = "LocKey#27566";
      if !LHUDAddonsConfig.JournalNotificationDisableQuestCore() {
        userData.soundEvent = n"QuestFailedPopup";
      };
      userData.soundAction = n"OnOpen";
      userData.animation = n"notification_quest_failed";
      userData.dontRemoveOnRequest = true;
      notificationData.time = this.m_showDuration;
      notificationData.widgetLibraryItemName = n"notification_quest_failed";
      notificationData.notificationData = userData;
      this.AddNewNotificationData(notificationData);
      break;
    default:
      return;
  };
}
