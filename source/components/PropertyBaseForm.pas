{*======================================================================*
 | PropertyBaseForm                                                     |
 |                                                                      |
 | Base class for property tree/page forms.  I like this one a lot!     |
 |                                                                      |
 | The contents of this file are subject to the Mozilla Public License  |
 | Version 1.1 (the "License"); you may not use this file except in     |
 | compliance with the License. You may obtain a copy of the License    |
 | at http://www.mozilla.org/MPL/                                       |
 |                                                                      |
 | Software distributed under the License is distributed on an "AS IS"  |
 | basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See  |
 | the License for the specific language governing rights and           |
 | limitations under the License.                                       |
 |                                                                      |
 | Copyright � Colin Wilson 2005,2006  All Rights Reserved              |
 |                                                                      |
 | Version  Date        By    Description                               |
 | -------  ----------  ----  ------------------------------------------|
 | 1.0      19/01/2005  CPWW  Original                                  |
 | 1.1      01/02/2006  CPWW  Generic version                           |
 *======================================================================*}

unit PropertyBaseForm;

interface

{$region 'Interface ''Uses'' section'}
uses
  WinAPI.Windows, WinAPI.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, VirtualTrees, PropertyPageForm, System.Contnrs, Vcl.StdCtrls,
  cmpPersistentPosition, Vcl.Menus;
{$include 'compilers.inc'}  // Use Mike Lischke's version detection

{$endregion}

{$region 'Global Constants'}
const
  WM_UPDATESPLITTER = WM_USER + $201;

{$endregion}

{$region 'GlobalTypes'}
type
  TfmPropertyBase = class;

//----------------------------------------------------------------------
// TPropertyPageDetails class maintains the tree structure for the form.
//
// Each node of the tree contains a TPropertyPageClass containing the
// form's class, an optional TPropertyPageData class containing persistent
// data, and Child, Parent and Sibling classes to make up the tree.

  TPropertyPageDetails = class
  private
    FPropertyPageClass: TPropertyPageClass;
    FChild: TPropertyPageDetails;
    FSibling: TPropertyPageDetails;
    FParent: TPropertyPageDetails;
    FData: TPropertyPageData;
    function GetChild(idx: Integer): TPropertyPageDetails;
    function GetChildCount: Integer;
  public
    constructor Create (AOwner: TfmPropertyBase; APropertyPageClass: TPropertyPageClass; AParent: TPropertyPageDetails; const ACaption, AHelpText, AHelpKeyWord: string; AParam: Integer = 0);
    destructor Destroy; override;
    property PropertyPageClass: TPropertyPageClass read FPropertyPageClass;

    property Sibling: TPropertyPageDetails read FSibling;
    property FirstChild: TPropertyPageDetails read FChild;
    property Parent: TPropertyPageDetails read FParent;
    property ChildCount: Integer read GetChildCount;
    property Child [idx: Integer]: TPropertyPageDetails read GetChild;
    property Data: TPropertyPageData read FData;
  end;

  TPropertyPageDetailsProc = procedure (page: TPropertyPageDetails; param: pointer; var continue: Boolean) of object;

//----------------------------------------------------------------------
// TfmPropertyBase is the base class for derived property tree forms

  TfmPropertyBase = class(TForm)
    pnlOptions: TPanel;
    vstSections: TVirtualStringTree;
    Splitter1: TSplitter;
    pnlButtons: TPanel;
    Bevel1: TBevel;
    btnOK: TButton;
    btnCancel: TButton;
    PersistentPosition1: TPersistentPosition;
    btnApply: TButton;
    PopupMenu1: TPopupMenu;
    ExpandAll1: TMenuItem;
    CollapseAll1: TMenuItem;
    btnHelp: TButton;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnHelpClick(Sender: TObject);
    procedure CollapseAll1Click(Sender: TObject);
    procedure ExpandAll1Click(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure vstSectionsGetText(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: String);
    procedure FormShow(Sender: TObject);
    procedure vstSectionsFocusChanged(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex);
    procedure btnOKClick(Sender: TObject);
    procedure vstSectionsInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure vstSectionsInitChildren(Sender: TBaseVirtualTree;
      Node: PVirtualNode; var ChildCount: Cardinal);
    procedure FormDestroy(Sender: TObject);
  private
    FPropertyPageDetails: TObjectList;
    FDetailsConstraints: TPoint;
    FUseConstraints: Boolean;
    FSaved: Boolean;
    FSelectedPage: TfmPropertyPage;
    FOrigHelpType: THelpType;
    FOrigHelpContext: Integer;
    FOrigHelpKeyWord: string;
    FFixTaskWindowThing: Boolean;

    procedure DoGetLargestConstraints (details: TPropertyPageDetails; param: pointer; var continue: Boolean);
    procedure DoSavePropertyPageSettings (page: TPropertyPageDetails; param: pointer; var continue: Boolean);
    procedure DoCancelPropertyPageSettings (page: TPropertyPageDetails; param: pointer; var continue: Boolean);
    procedure DoCheckFormClassMatches (details: TPropertyPageDetails; param: pointer; var continue: Boolean);
    procedure DoCheckDataMatches (details: TPropertyPageDetails; param: pointer; var continue: Boolean);


    function GetNodePropertyPageDetails (node: PVirtualNode): TPropertyPageDetails;
    procedure SetNodePropertyPageDetails (node: PVirtualNode; details: TPropertyPageDetails);
    procedure SelectPage (details: TPropertyPageDetails);
    procedure CancelChanges;
    function FindSameData (formClass: TPropertyPageClass): TPropertyPageData;
    procedure WmUpdateSplitter (var msg: TMessage); message WM_UPDATESPLITTER;

  protected
    function SaveSettings: Boolean; virtual;
    function FindDetailsWithData (data: TPropertyPageData): TPropertyPageDetails;
    procedure DoApply; virtual;
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    function ShowModal: Integer; override;

    function AddPropertyPageDetails (APropertyPageClass: TPropertyPageClass; AParent: TPropertyPageDetails; const ACaption: string = ''; const AHelpText: string = ''; const AHelpKeyWord: string = ''; AParam: Integer = 0): TPropertyPageDetails;
    function ForEachPropertyPageDetails (proc: TPropertyPageDetailsProc; param: pointer): TPropertyPageDetails;

    property FixTaskWindowThing: Boolean read FFixTaskWindowThing write FFixTaskWindowThing;
  end;

//----------------------------------------------------------------------
// TfmPropertyPageDummy class provides an empty 'separator' property
// page.  It's also used as a cracker class(!)
  TfmPropertyPageDummy = class (TfmPropertyPage)
  public
    class function GetDataClass: TPropertyPageDataClass; override;
    procedure PopulateControls (AData: TPropertyPageData); override;
  end;
{$endregion}

implementation

uses PropertyGlobals, Math;

{$R *.dfm}

type
  PObject = ^TObject;

{$region 'Helper procedure and functions'}

{*----------------------------------------------------------------------*
 | procedure AdjustFormConstraints                                      |
 |                                                                      |
 | Adjust a form's constraints to take into account 'large fonts'       |
 |                                                                      |
 | Parameters:                                                          |
 |   form: TForm                       The form to fix                 |
 *----------------------------------------------------------------------*}
procedure AdjustFormConstraints (form: TForm);

  function AdjustForLargeFonts (x: Integer): Integer;
  begin
    Result := (x * Screen.PixelsPerInch) div 96
  end;

begin
  if form.Scaled then with form.Constraints do
  begin
    MinWidth := AdjustForLargeFonts (MinWidth);
    MinHeight := AdjustForLargeFonts (MinHeight);
    MaxWidth := AdjustForLargeFonts (MaxWidth);
    MaxHeight := AdjustForLargeFonts (MaxHeight)
  end
end;

{*----------------------------------------------------------------------*
 | procedure FixFormConstraints                                         |
 |                                                                      |
 | It seems that Delphi gets the constraints wrong for the child forms. |
 | At design time you specify the constraints - including the size of   |
 | the frame.  But at runtime there's no frame, so they are too big.    |
 | Reduce the constraints using this function after creating the child  |
 | windows                                                              |
 |                                                                      |
 | nb.  Fixed in BDS 2006                                               |
 |                                                                      |
 | Parameters:                                                          |
 |   form: TForm                       The form to fix                 |
 *----------------------------------------------------------------------*}
procedure FixFormConstraints (form: TForm);
begin
  with form do
  begin

  {$ifndef DELPHI_10_UP}

    Constraints.MinWidth := Constraints.MinWidth - GetSystemMetrics (SM_CXSIZEFRAME) * 2;
    Constraints.MinHeight := Constraints.MinHeight - GetSystemMetrics (SM_CYSIZE) - 2 * getSystemMetrics (SM_CYSIZEFRAME);
  {$endif}

  {$ifndef DELPHI_10_UP}
  // This one was fixed in BDS 2006 SP2
    AdjustFormConstraints (form);
  {$endif}
  end
end;

{$endregion}

{$region 'TfmPropertyBase methods'}

{ TfmPropertyBase }

{*----------------------------------------------------------------------*
 | function TfmPropertyBase.AddPropertyPageDetails                      |
 |                                                                      |
 | Create and add a new TPropertyPageDetails class to the tree.  The    |
 | details class holds data for the class in a TPropertyPageData        |
 | derived instance.  It also holds the class reference of a            |
 | TPropertyPageForm, which it uses to create the form dynamically      |
 | when it's tree item is selected.                                     |
 |                                                                      |
 | Parameters:                                                          |
 |   APropertyPageClass: TPropertyPageClass                             |
 |                                      The class of the property page  |
 |                                      form to add.                    |
 |                                                                      |
 |   AParent: TPropertyPageDetails      The parent page details         |
 |   const ACaption: string            Form caption.                   |
 |   const AHelpText: string           Form help text                  |
 |   AParam: Integer                   Parameter passed to page data   |
 |                                                                      |
 | The function returns the TPropertyPageDetails class for the page     |
 *----------------------------------------------------------------------*}
function TfmPropertyBase.AddPropertyPageDetails(
  APropertyPageClass: TPropertyPageClass; AParent: TPropertyPageDetails; const ACaption: string; const AHelpText, AHelpKeyWord: string; AParam: Integer): TPropertyPageDetails;
var
  details: TPropertyPageDetails;
  p: ^TPropertyPageDetails;
begin
  details := TPropertyPageDetails.Create(self, APropertyPageClass, AParent, ACaption, AHelpText, AHelpKeyWord, AParam);
  if AParent = Nil then
  begin
    FPropertyPageDetails.Add(details);
    vstSections.RootNodeCount := FPropertyPageDetails.Count
  end
  else
  begin
    p := @AParent.FirstChild;
    while p^ <> Nil do
      p := @p^.Sibling;
    p^ := details
  end;

  Result := details;
end;

{*----------------------------------------------------------------------*
 | function TfmPropertyBase.btnApplyClick                               |
 |                                                                      |
 | OnClick handler for the 'Apply' button.
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.btnApplyClick(Sender: TObject);
begin
  if SaveSettings then
    DoApply;
end;

procedure TfmPropertyBase.btnHelpClick(Sender: TObject);
var
  kw: string;
  co: Integer;
begin
  kw := '';
  co := 0;

  if Assigned(FSelectedPage) then
    if (FSelectedPage.HelpType = htKeyWord) and (FSelectedPage.HelpKeyWord <> '') then
    begin
      kw := FSelectedPage.HelpKeyWord;
      if kw = '' then
        kw := FSelectedPage.AltKeyWord
    end
    else
      if (FSelectedPage.HelpType = htContext ) then
        co := FSelectedPage.HelpContext;

  if (kw = '') and (co = 0) then
    if FOrigHelpType = htContext then
      co := FOrigHelpContext
    else
      kw := FOrigHelpKeyWord;


  if kw <> '' then
    Application.HelpKeyWord(kw)
  else
    if co <> 0 then
      Application.HelpContext(co)
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.btnOKClick                                 |
 |                                                                      |
 | Onclick handler for the OK button.                                   |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.btnOKClick(Sender: TObject);
begin
  FSaved := True;
  if SaveSettings then
    ModalResult := mrOK;
end;

procedure TfmPropertyBase.CancelChanges;
begin
  ForEachPropertyPageDetails (DoCancelPropertyPageSettings, nil);
end;

procedure TfmPropertyBase.CollapseAll1Click(Sender: TObject);
begin
  vstSections.FullCollapse;
end;

{*----------------------------------------------------------------------*
 | constructor TfmPropertyBase.Create                                   |
 |                                                                      |
 | Constructor.  Create the list of PropertyPageDetails root items.     |
 *----------------------------------------------------------------------*}
constructor TfmPropertyBase.Create(AOwner: TComponent);
begin
  inherited Create (AOwner);
  FPropertyPageDetails := TObjectList.Create;
  FPropertyPageDetails.OwnsObjects := True;
end;

{*----------------------------------------------------------------------*
 | destructor TfmPropertyBase.Destroy                                   |
 |                                                                      |
 | Destructor. Destroy the list of root Details items.  This will       |
 | destroy the items themselves, and destroying an item destroys its    |
 | child items, too.                                                    |
 *----------------------------------------------------------------------*}
destructor TfmPropertyBase.Destroy;
begin
  FPropertyPageDetails.Free;
  inherited;
end;

procedure TfmPropertyBase.DoApply;
begin
  if Assigned(Application.MainForm) then
    PostMessage (Application.MainForm.Handle,  WM_APPLYCHANGES, 0, 0);
end;

procedure TfmPropertyBase.DoCancelPropertyPageSettings(
  page: TPropertyPageDetails; param: pointer; var continue: Boolean);
begin
  if Assigned(page.FData) then
                // nb.  FData.Initialized won't be set(and its data won't be
                //      valid unless a page has been selected.
    if page.FData.Initialized then
      page.FData.Cancel
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.DoCheckDataMatches                         |
 |                                                                      |
 | ForEach callback routine used in FindDetailsWithData.  Set           |
 | 'continue := False' when the function is passed a 'details' class    |
 | whose data matches the data given                                    |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.DoCheckDataMatches(details: TPropertyPageDetails;
  param: pointer; var continue: Boolean);
begin
  continue := details.FData <> param
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.DoCheckFormClassMatches                    |
 |                                                                      |
 | ForEach callback routine used in FindSameData.  Set 'continue :=     |
 | False' when the function is passed a 'details' class whose form      |
 | class matches the given form class.                                  |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.DoCheckFormClassMatches(
  details: TPropertyPageDetails; param: pointer; var continue: Boolean);
begin
  continue := details.FPropertyPageClass <> param
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.DoGetLargestConstraints                    |
 |                                                                      |
 | ForEach handler used to find the largest form's constraints.         |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.DoGetLargestConstraints(details: TPropertyPageDetails;
  param: pointer; var continue: Boolean);
var
  p: PPoint;
begin
  p := PPoint(param);

  p.X := Max (details.FData.MinX, p.X);
  p.Y := Max (details.FData.MinY, p.Y)
end;

{*----------------------------------------------------------------------*
 | prcoedure TfmPropertyBase.DoSavePropertyPageSettings                 |
 |                                                                      |
 | For Each handler used to apply the settings for a given form         |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.DoSavePropertyPageSettings(
  page: TPropertyPageDetails; param: pointer; var continue: Boolean);
begin
  if Assigned(page.FData) then
                // nb.  FData.Initialized won't be set(and its data won't be
                //      valid unless a page has been selected.
    if page.FData.Initialized then
      continue := page.FData.Apply
end;

procedure TfmPropertyBase.ExpandAll1Click(Sender: TObject);
begin
  vstSections.FullExpand;
end;

{*----------------------------------------------------------------------*
 | function TfmPropertyBase.FindDetailsWithData                         |
 |                                                                      |
 | Find the property page whose data matches the given data.            |
 *----------------------------------------------------------------------*}
function TfmPropertyBase.FindDetailsWithData(
  data: TPropertyPageData): TPropertyPageDetails;
begin
  Result := ForEachPropertyPageDetails (DoCheckDataMatches, data);
end;

{*----------------------------------------------------------------------*
 | function TfmPropertyBase.FindSameData                                |
 |                                                                      |
 | Find the first page whose form class matches the given form class    |
 *----------------------------------------------------------------------*}
function TfmPropertyBase.FindSameData(
  formClass: TPropertyPageClass): TPropertyPageData;
var
  details: TPropertyPageDetails;
begin
  details := ForEachPropertyPageDetails (DoCheckFormClassMatches, formClass);
  if Assigned(details) then
    Result := details.FData
  else
    Result := Nil
end;

{*----------------------------------------------------------------------*
 | function TfmPropertyBase.ForEachPropertyPageDetails                  |
 |                                                                      |
 | Iterate through the tree of page details, calling 'proc' for each    |
 | one.                                                                 |
 |                                                                      |
 | 'Proc' may request that the iteration stops at a particular          |
 | page details.  In which case, the function returns this.             |
 |                                                                      |
 | Parameters:                                                          |
 |   proc: TPropertyPageDetailsProc     Method to call for each node    |
 |   param: pointer                    Parameter to pass to the        |
 |                                      iterator proc.                  |
 *----------------------------------------------------------------------*}
function TfmPropertyBase.ForEachPropertyPageDetails(proc: TPropertyPageDetailsProc; param: pointer): TPropertyPageDetails;
var
  i: Integer;
  cont: Boolean;
  rv: TPropertyPageDetails;

  procedure DoForEach (details: TPropertyPageDetails);
  begin
    if Assigned(details) then
    begin
      rv := details;
      proc (details, param, cont);
      if cont then DoForEach (details.FirstChild);
      if cont then DoForEach (details.Sibling)
    end
  end;

begin
  rv := Nil;
  cont := True;
  for i := 0 to FPropertyPageDetails.Count - 1 do
  begin
    DoForEach (TPropertyPageDetails (FPropertyPageDetails [i]));
    if not cont then
      break
  end;

  // If 'cont', the iterator reached the end without being told to 'stop' on
  // a particular PropertyPageDetails.
  if cont then Result := Nil else Result := rv
end;

procedure TfmPropertyBase.FormDestroy(Sender: TObject);
begin
  PersistentPosition1.SetValue('Splitter', vstSections.Width);
  if not FSaved then
    CancelChanges;
end;

procedure TfmPropertyBase.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_f1 then
  begin
    btnHelpClick (nil);
    Key := 0
  end
end;

{*----------------------------------------------------------------------*
 | TfmPropertyBase.FormShow                                             |
 |                                                                      |
 | OnShow handler.  Initialize the form.                                |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.FormShow(Sender: TObject);
var
  n: PVirtualNode;
begin
  FDetailsConstraints := Point(0, 0);
  FOrigHelpType := HelpType;
  FOrigHelpContext := HelpContext;
  FOrigHelpKeyWord := HelpKeyWord;

  HelpKeyWord := '';
  HelpContext := 0;
  HelpType := htContext;

  // Get the largest constraints
  ForEachPropertyPageDetails (DoGetLargestConstraints, @FDetailsConstraints);
  FUseConstraints := (FDetailsConstraints.X <> 0) and (FDetailsConstraints.Y <> 0);

  if FUseConstraints then
  begin
    pnlOptions.Constraints.MinWidth := FDetailsConstraints.X;
    pnlOptions.Constraints.MinHeight := FDetailsConstraints.Y + Bevel1.Height;
  end;

  n := vstSections.GetFirst;
  if n <> Nil then
  begin
    vstSections.FocusedNode := n;
    vstSections.Selected [n] := True
  end;

  vstSections.FullExpand;

  PostMessage (Handle, WM_UPDATESPLITTER, 0, 0);
end;

{*----------------------------------------------------------------------*
 | function TfmPropertyBase.GetNodePropertyPageDetails                  |
 |                                                                      |
 | Return the TPropertyPageDetails assiciated with a tree node          |
 *----------------------------------------------------------------------*}
function TfmPropertyBase.GetNodePropertyPageDetails(
  node: PVirtualNode): TPropertyPageDetails;
var
  obj: PObject;
begin
  obj := vstSections.GetNodeData(node);

  if Assigned(obj) then
    Result := TPropertyPageDetails (obj^)
  else
    Result := Nil
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.SaveSettings                               |
 |                                                                      |
 | Apply the settings held in the property details data to the actual   |
 | settings held for XanaNews.  (This is called when the 'OK' button    |
 | is clicked)                                                          |
 *----------------------------------------------------------------------*}
function TfmPropertyBase.SaveSettings: Boolean;
var
  errorPage: TPropertyPageDetails;
begin
  errorPage := ForEachPropertyPageDetails (DoSavePropertyPageSettings, nil);
  Result := errorPage = Nil;
  if not result then
  begin
    SelectPage (errorPage);
    errorPage.Data.Error
  end
end;

type
  TMyPanel = class (TPanel)
  end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.SelectPage                                 |
 |                                                                      |
 | Called when a node is selected in the tree.  Create a form of the    |
 | correct class and initialize it with data held in details.FData      |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.SelectPage(details: TPropertyPageDetails);
var
  page: TfmPropertyPage;
  newPage: Boolean;
begin
        // (try to) provent flickering!
  SendMessage (pnlOptions.Handle, WM_SETREDRAW, 0, 0);
  try
                // Free the old form (if there was one)
    if pnlOptions.ControlCount > 1 then
    begin
      page := pnlOptions.Controls [1] as TfmPropertyPage;

      if Assigned(details) and (page.ClassType <> details.FPropertyPageClass) then
        FreeAndNil (page);
    end
    else
      page := Nil;

    if Assigned(details) then
    begin
      if not Assigned(page) then
      begin
                  // Create new form of the correct class.
        page := details.FPropertyPageClass.Create(self);
        FixFormConstraints (page);
        page.Parent := pnlOptions;
        newPage := True;
      end
      else
        newPage := False;

                // Populate the form
      TfmPropertyPageDummy (page).fPopulating := True;
      try
        page.PopulateControls(details.FData);
      finally
        TfmPropertyPageDummy (page).fPopulating := False
      end;

      if newPage then
      begin
        page.Visible := True;
        page.Align := alClient
      end
    end;

    FSelectedPage := page;
  finally
    SendMessage (pnlOptions.Handle, WM_SETREDRAW, 1, 0);
    RedrawWindow(pnlOptions.Handle,nil,0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_UPDATENOW);
  end
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.SetNodePropertyPageDetails                 |
 |                                                                      |
 | Set the given tree node's data to point to the given details class   |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.SetNodePropertyPageDetails(node: PVirtualNode;details: TPropertyPageDetails);
var
  obj: PObject;
begin
  obj := vstSections.GetNodeData(node);

  if Assigned(obj) then
    obj^ := details
end;

function TfmPropertyBase.ShowModal: Integer;
var
  WindowList: Pointer;
  SaveFocusState: TFocusState;
  SaveCursor: TCursor;
  SaveCount: Integer;
  ActiveWindow: HWnd;
begin
  CancelDrag;
  if Visible or not Enabled or (fsModal in FFormState) or
    (FormStyle = fsMDIChild) then
    raise EInvalidOperation.Create('Cannot show modal');
  if GetCapture <> 0 then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);
  ReleaseCapture;
  Application.ModalStarted;
  try
    Include(FFormState, fsModal);
    if (PopupMode = pmNone) and (Application.ModalPopupMode <> pmNone) then
    begin
      RecreateWnd;
      HandleNeeded;
    end;
    ActiveWindow := GetActiveWindow;
    SaveFocusState := Vcl.Forms.SaveFocusState;
    Screen.SaveFocusedList.Insert(0, Screen.FocusedForm);
    Screen.FocusedForm := Self;
    SaveCursor := Screen.Cursor;
    Screen.Cursor := crDefault;
    SaveCount := Screen.CursorCount;
    if FixTaskWindowThing then
      WindowList := DisableTaskWindows(Handle)
    else
      WindowList := DisableTaskWindows(0);
    try
      Show;
      try
        SendMessage(Handle, CM_ACTIVATE, 0, 0);
        ModalResult := 0;
        repeat
          Application.HandleMessage;
          if Application.Terminated then ModalResult := mrCancel else
            if ModalResult <> 0 then CloseModal;
        until ModalResult <> 0;
        Result := ModalResult;
        SendMessage(Handle, CM_DEACTIVATE, 0, 0);
        if GetActiveWindow <> Handle then ActiveWindow := 0;
      finally
        Hide;
      end;
    finally
      if Screen.CursorCount = SaveCount then
        Screen.Cursor := SaveCursor
      else Screen.Cursor := crDefault;
      EnableTaskWindows(WindowList);
      if Screen.SaveFocusedList.Count > 0 then
      begin
        Screen.FocusedForm := Screen.SaveFocusedList.First;
        Screen.SaveFocusedList.Remove(Screen.FocusedForm);
      end else Screen.FocusedForm := nil;
      if ActiveWindow <> 0 then SetActiveWindow(ActiveWindow);
      RestoreFocusState(SaveFocusState);
      Exclude(FFormState, fsModal);
    end;
  finally
    Application.ModalFinished;
  end;
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.vstSectionsFocusChanged                    |
 |                                                                      |
 | OnFocusedChanged handler for the tree.  Create the page for the      |
 | newly selected node.                                                 |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.vstSectionsFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
begin
  SelectPage (GetNodePropertyPageDetails (Node));
end;

{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.vstSectionsGetText                         |
 |                                                                      |
 | OnGetText handler for the tree                                       |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.vstSectionsGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var
  d: TPropertyPageDetails;
begin
  d := GetNodePropertyPageDetails (Node);
  CellText := d.FData.Caption
end;


{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.vstSectionsInitChildren                    |
 |                                                                      |
 | OnInitChild function for the tree                                    |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.vstSectionsInitChildren(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var ChildCount: Cardinal);
var
  details: TPropertyPageDetails;
begin
  details := GetNodePropertyPageDetails (Node);
  if Assigned(details) then
    ChildCount := details.ChildCount
  else
    ChildCount := 0
end;


{*----------------------------------------------------------------------*
 | procedure TfmPropertyBase.vstSectionsInitNode                        |
 |                                                                      |
 | OnInitNode handler for the tree                                      |
 *----------------------------------------------------------------------*}
procedure TfmPropertyBase.vstSectionsInitNode(Sender: TBaseVirtualTree;
  ParentNode, Node: PVirtualNode;
  var InitialStates: TVirtualNodeInitStates);
var
  details, parentDetails: TPropertyPageDetails;
begin
  if ParentNode = Nil then
    details := TPropertyPageDetails (FPropertyPageDetails [Node.Index])
  else
  begin
    parentDetails := GetNodePropertyPageDetails (ParentNode);
    details := parentDetails.Child [node.Index]
  end;
  SetNodePropertyPageDetails (node, details);
  if details.ChildCount > 0 then
    InitialStates := InitialStates + [ivsHasChildren];
end;

procedure TfmPropertyBase.WmUpdateSplitter(var msg: TMessage);
var
  w: Integer;
begin
  w := PersistentPosition1.GetValue('Splitter');

  if (w > 0) and (w < ClientWidth) then
    vstSections.Width := w;
end;

{$endregion}

{$region 'TPropertyPageDetails methods'}

{ TPropertyPageDetails }

{*----------------------------------------------------------------------*
 | constructor TPropertyPageDetails.Create                              |
 |                                                                      |
 | Create a TPropetryPageDetails (tree node class) and create it's data |
 | class.  Don't initialize the data class (until its page is displayed)|
 | - but fill in its MinX, MaxX, Caption and HelpText properties        |
 *----------------------------------------------------------------------*}
constructor TPropertyPageDetails.Create(AOwner: TfmPropertyBase; APropertyPageClass: TPropertyPageClass;
  AParent: TPropertyPageDetails; const ACaption, AHelpText, AHelpKeyWord: string; AParam: Integer);
var
  dataClass: TPropertyPageDataClass;
  tempPropertyPage: TfmPropertyPage;
  tempData: TPropertyPageData;
  caption: string;
  helpText: string;
  helpKeyWord: string;
  minX, minY: Integer;
begin
  FPropertyPageClass := APropertyPageClass;
  FParent := AParent;
  tempPropertyPage := Nil;
  try

  // In order to get the form's constraints, caption, etc. we need
  // to create a temporary instance of one.  But only the first
  // time for each form class.  If we've already created a temporary
  // instance for this class, use it's constraints & caption details.

    dataClass := FPropertyPageClass.GetDataClass;
    tempData := AOwner.FindSameData (FPropertyPageClass);

    if Assigned(tempData) then

    begin       // We've already created data for this form class
                // so use its settings

      if ACaption <> '' then
        caption := ACaption
      else
        caption := tempData.Caption;

      if AHelpText <> '' then
        helpText := AHelpText
      else
        helpText := tempData.HelpText;

      if AHelpKeyWord <> '' then
        helpKeyWord := AHelpKeyWord
      else
        helpKeyWord := tempData.HelpKeyWord;

      minX := tempData.MinX;
      minY := tempData.MinY
    end
    else

    begin       // First time data is created for this form class.  So
                // create a tempoary instance of the form to get its
                // constraints and caption.

      tempPropertyPage := FPropertyPageClass.Create(nil);
      FixFormConstraints (tempPropertyPage);

      if (ACaption = '') and (tempPropertyPage.Caption <> tempPropertyPage.Name) then
        caption := tempPropertyPage.Caption
      else
        caption := ACaption;

      helpKeyWord := AHelpKeyWord;

      if AHelpText <> '' then
        helpText := AHelpText
      else
        helpText := tempPropertyPage.stSectionDetails.Caption;

      minX := tempPropertyPage.Constraints.MinWidth;
      minY := tempPropertyPage.Constraints.MinHeight;
    end;

                // Create the data class.
    FData := dataClass.Create (caption, helpText, helpKeyWord, minX, minY, AParam);
  finally
    tempPropertyPage.Free
  end
end;

{*----------------------------------------------------------------------*
 | destructor TPropertyPageDetails.Destroy                              |
 |                                                                      |
 | Recursively destroy a property page details class and its siblings & |
 | chidren.                                                             ||
 *----------------------------------------------------------------------*}
destructor TPropertyPageDetails.Destroy;
begin
  FData.Free;
  FChild.Free;
  FSibling.Free;  // Obviously the root items 'Sibling's aren't populated!

  inherited;
end;

{*----------------------------------------------------------------------*
 | function TPropertyPageDetails.GetChild                               |
 |                                                                      |
 | Get the 'nth' child node of a details class                          |
 *----------------------------------------------------------------------*}
function TPropertyPageDetails.GetChild(idx: Integer): TPropertyPageDetails;
begin
  Result := FChild;
  while (result <> Nil) and (idx > 0) do
  begin
    Result := result.Sibling;
    Dec(idx)
  end
end;

{*----------------------------------------------------------------------*
 | function TPropertyPageDetails.GetChildCount                          |
 |                                                                      |
 | Count the children for a given details node                          |
 *----------------------------------------------------------------------*}
function TPropertyPageDetails.GetChildCount: Integer;
var
  p: TPropertyPageDetails;
begin
  Result := 0;
  p := FChild;
  while p <> Nil do
  begin
    Inc(Result);
    p := p.Sibling
  end
end;

{$endregion}

{ TfmPropertyPageDummy }

class function TfmPropertyPageDummy.GetDataClass: TPropertyPageDataClass;
begin
  Result := TPropertyPageData
end;

procedure TfmPropertyPageDummy.PopulateControls(AData: TPropertyPageData);
begin
  stSectionDetails.Caption := AData.HelpText
end;


end.
