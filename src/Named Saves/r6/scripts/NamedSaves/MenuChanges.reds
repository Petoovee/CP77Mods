module NamedSaves.UI
import NamedSaves.Codeware.UI.*
import NamedSaves.Utils.*

@addField(SaveGameMenuGameController)
private let m_nameInput: ref<HubTextInput>;

@addField(SaveGameMenuGameController)
private let m_nameInputContainer: ref<inkCompoundWidget>;

@wrapMethod(SaveGameMenuGameController)
protected cb func OnInitialize() -> Bool {
  wrappedMethod();

  // Insert input
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  let outerContainer: ref<inkCompoundWidget> = root.GetWidget(n"holder") as inkCompoundWidget;
  this.m_nameInputContainer = new inkVerticalPanel();
  this.m_nameInputContainer.SetName(n"InputContainer");
  this.m_nameInputContainer.SetFitToContent(true);
  this.m_nameInputContainer.SetTranslation(new Vector2(730.0, 140.0));
  this.m_nameInputContainer.SetHAlign(inkEHorizontalAlign.Left);
  this.m_nameInputContainer.SetVAlign(inkEVerticalAlign.Center);
  this.m_nameInputContainer.SetAnchor(inkEAnchor.CenterLeft );
  this.m_nameInputContainer.SetAnchorPoint(new Vector2(1.0, 0.0));
  this.m_nameInputContainer.Reparent(outerContainer, 1);
  this.m_nameInput = HubTextInput.Create();
  this.m_nameInput.SetName(n"InputText");
  this.m_nameInput.SetMaxLength(64);
  this.m_nameInput.Reparent(this.m_nameInputContainer);

  this.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"OnGlobalInput");
}

// Reset input focus on elsewhere click - copy-pasted from psiberx samples ^^
@addMethod(SaveGameMenuGameController)
protected cb func OnGlobalInput(evt: ref<inkPointerEvent>) -> Void {
	if evt.IsAction(n"mouse_left") {
		if !IsDefined(evt.GetTarget()) || !evt.GetTarget().CanSupportFocus() {
			this.RequestSetFocus(null);
		};
	};
}

// Save input text on save completion event
@wrapMethod(SaveGameMenuGameController)
protected cb func OnSavingComplete(success: Bool, locks: array<gameSaveLock>) -> Bool {
  let inputText: String = this.m_nameInput.GetText();
  if NotEquals(inputText, "") {
    AddCustomNoteToNewestSave(inputText);
    this.m_nameInput.SetText("");
  };

  wrappedMethod(success, locks);
}

@addField(LoadListItem)
private let m_customNote: ref<inkText>;

@wrapMethod(LoadListItem)
protected cb func OnInitialize() -> Bool {
  wrappedMethod();
  let root: ref<inkCompoundWidget> = this.GetRootCompoundWidget();
  let container: ref<inkCompoundWidget> = root.GetWidget(n"Not_Empty_Slot/inkHorizontalPanelWidget3") as inkCompoundWidget;

  let newText: ref<inkText> = new inkText();
  newText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  newText.SetName(n"NamedSaveLabel");
  newText.SetFontStyle(n"Regular");
  newText.SetFontSize(38);
  newText.SetLetterCase(textLetterCase.OriginalCase);
  newText.SetFitToContent(true);
  newText.SetHAlign(inkEHorizontalAlign.Fill);
  newText.SetVAlign(inkEVerticalAlign.Fill);
  newText.SetAnchor(inkEAnchor.BottomRight);
  newText.SetMargin(new inkMargin(20.0, 0.0, 50.0, 0.0));
  newText.SetAnchorPoint(new Vector2(1.0, 1.0));
  newText.SetOpacity(0.6);
  newText.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
  newText.BindProperty(n"tintColor", n"MainColors.Green");
  newText.Reparent(container);
  this.m_customNote = newText;
  container.SetChildOrder(inkEChildOrder.Backward);
}

// Read custom notes by save index
@wrapMethod(LoadListItem)
public final func SetMetadata(metadata: ref<SaveMetadataInfo>) -> Void {
  wrappedMethod(metadata);

  let index: Int32 = GetSaveIndexFromInternalName(metadata.internalName);
  let note: String = GetNoteForSaveIndex(index);
  if NotEquals(index, -1) && NotEquals(note, "") {
    this.m_customNote.SetVisible(true);
    this.m_customNote.SetText(note);
  } else {
    this.m_customNote.SetVisible(false);
  };
}
