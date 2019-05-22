{***************************************************************}
{                                                               }
{                 TPrintService  для Delphi                     }
{                  © 1997 Дмитрий Васильев                      }
{                                                               }
{ Компонент предназначен для реализации всех функций, связанных }
{ с выводом на печать: выбор принтера, его настройка,           }
{ удобный предварительный просмотр (включая масштабирование) и  }
{ собственно печать.                                            }
{                                                               }
{***************************************************************}
{                                                               }
{       Некоторые добавления, исправления, расширения           }
{                  © 2002 Румянцев Алексей                      }
{                                                               }
{---------------------------------------------------------------}
{                                                               }
{ Оригинальный вариант TPrintService, распростронялся           }
{ бесплатно без каких-либо условий, гарантий и без              }
{ лицензии, с оговоркой что-то типа "пользуйтесь наздоровье"    }
{ В настоящий момент авторская страница, в и-нете отсутствует,  }
{ e-mail Дмитрия Васильева утерян. Поэтому данная версия        }
{ компонента распространяется на тех же условиях.               }
{ В оригинальный вариант было внесено несколько незначительных  }
{ изменеий. Сам оригинал по прошествии лет не сохранился.       }
{                                                               }
{ TPrintService - удобен тем, что позволяет рисовать на канве   }
{ принтера(или в окне предварительного просмотра), неограничивая}
{ себя рамками Band'ов, и создавать свои шаблоны печати страниц }
{ или каждой из страниц в зависимости от задачь и настроения.   }
{                                                               }
{***************************************************************}

unit PrnServ;

interface

uses Windows, SysUtils, Messages, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, Printers, ComCtrls, ExtCtrls,  Buttons;

// const
//  TB_Prev = 0;
type
  TInternalBtnState = set of (ibsFocused, ibsPressed, ibsSpace,
    ibsMouseInControl);
  TBtnState = (bsDown, bsDrawFocus, bsMultiline, bsShowCaption, bsFrameRect);
  TBtnStates = set of TBtnState;

  TRptButton = class(TCustomControl)
  private
    FInternalBtnState: TInternalBtnState;
    FBtnStates: TBtnStates;
    procedure SetBtnStates(const Value: TBtnStates);
  private
    procedure SetInternalBtnState(const Value: TInternalBtnState);
    property  InternalBtnState: TInternalBtnState read FInternalBtnState write SetInternalBtnState;
  private
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMSysColorChange(var Message: TMessage); message CM_SYSCOLORCHANGE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    {procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;}
    procedure WMSetFocus(var Message: TMessage); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TMessage); message WM_KILLFOCUS;
    procedure CNCommand(var Message: TWMCommand); message CN_COMMAND;
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp  (var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property Caption;
    property Color;
    property Ctl3D;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property BtnStates: TBtnStates read FBtnStates write SetBtnStates default
             [bsDrawFocus, bsShowCaption, bsFrameRect];

    property OnClick;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  TPreviewForm = class;

  TCustomPage = class(TCustomControl)
  private
  public
    property Canvas;
  end;

  TPageControl = class(TCustomPage)
  private
    FBmp: TBitmap;
    {FMetaFile: TMetaFile;}
    FPreviewer: TPreviewForm;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure PaintPage;
    procedure UpdatePage(AWidth, AHeight: Integer);
    property Previewer: TPreviewForm read FPreviewer write FPreviewer;
  end;

  TDrawTarget = (dtPreview, dtPrint);

  TViewMode = (vm200, vm150, vm100, vm75, vm50, vm25, vm10,
    vmPageWidth, vmFullPage);

  TDrawEvent = procedure (Sender: TObject; Canvas: TCanvas; PageNumber: Integer;
    DrawTarget: TDrawTarget) of object;

  TPrintService = class;

  TToolButton = (TB_Prev, TB_Next, TB_Zoom, TB_Print, {btnDlgPrint, }
               TB_Options, TB_Close);
  TToolButtons = array[TToolButton] of TRptButton; // TRptButton; TSpeedButton

  TMenuList = (MI_10, MI_25, MI_50, MI_75, MI_100, MI_150, MI_200,
    mi_sep1, MI_WIDTH, MI_FULL);
  TMenuItems = array[TMenuList] of TMenuItem;
  TAfterPrinterSetupDialog = procedure of object;
  TOnFormClose             = procedure of object;
  TPreviewForm = class(TForm)
    sbxMain: TScrollBox;
    stbMain: TStatusBar;
    tbrMain: TPanel;
  private
    { Private declarations }
    //
    FAfterPrinterSetupDialog : TAfterPrinterSetupDialog;
    FOnFormClose             : TOnFormClose;
    //
    FViewMode: TViewMode;
    FPageCount: Integer;
    FPageIndex: Integer;
    FPageControl: TPageControl;
    FPrintService: TPrintService;
    procedure SetViewMode(Value: TViewMode);
    procedure SetPageCount(Value: Integer);
    procedure SetPageIndex(Value: Integer);
    procedure WMGetMinMaxInfo(var Msg: TMessage); message wm_GetMinMaxInfo;
  private
    MenuItems : TMenuItems;
    FZoomMenu : TPopupMenu;
    Btns      : TToolButtons;
    procedure ZoomExecute(Sender: TObject);
    procedure tbtPrinterSetupDialogClick(Sender: TObject);
    procedure tbtPrevPageClick(Sender: TObject);
    procedure tbtNextPageClick(Sender: TObject);
    {procedure tbtPrintDialogClick(Sender: TObject);}
    procedure tbtZoomClick(Sender: TObject);
    procedure tbtCloseClick(Sender: TObject);
    procedure tbtPrintClick(Sender: TObject);
  private
    { Private declarations }
    procedure UpdatePageSetup;
    procedure UpdatePreviewer;
    procedure UpdatePreview;
    property PrintService: TPrintService read FPrintService write FPrintService;
    property PageCount: Integer read FPageCount write SetPageCount;
  protected
    procedure Resize; override;
    procedure DoClose(var Action: TCloseAction); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    property ViewMode: TViewMode read FViewMode write SetViewMode;
    property PageIndex: Integer read FPageIndex write SetPageIndex;
    property OnPrinterSetupDialog : TAfterPrinterSetupDialog read FAfterPrinterSetupDialog write FAfterPrinterSetupDialog;
    property OnFormClose : TOnFormClose read FOnFormClose write FOnFormClose;
  end;

  TPrintService = class(TComponent)
  private
    { Private declarations }
    FPageCount: Integer;
    FPreviewerCaption: string;
    FPrintDialog: TPrintDialog;
    FPrinterSetupDialog: TPrinterSetupDialog;
    FPreviewer: TPreviewForm;
    FOnCreate: TNotifyEvent;
    FOnDraw: TDrawEvent;
    FOnPrinterSetupChange: TNotifyEvent;
    FOnPrint: TNotifyEvent;
    FOnPreviewOpen: TNotifyEvent;
    FOnPreviewClose: TNotifyEvent;
    procedure SetPageCount(Value: Integer);
    procedure SetPreviewerCaption(Value: string);
  protected
    { Protected declarations }
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoDraw(Canvas: TCanvas; PageNumber: Integer;
      DrawTarget: TDrawTarget); virtual;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure OpenPreview;
    procedure ClosePreview;
    procedure Print(page : Integer); virtual;
    procedure PrintDialog(Page : Integer);
    procedure PrinterSetupDialog;
    procedure UpdatePreview;
    function  PageSizeX: Integer;
    function  PageSizeY: Integer;
    property  Previewer: TPreviewForm read FPreviewer;
  published
    { Published declarations }
    property PageCount: Integer read FPageCount write SetPageCount;
    property PreviewerCaption: string read FPreviewerCaption write SetPreviewerCaption;
    property OnCreate: TNotifyEvent read FOnCreate write FOnCreate;
    property OnDraw: TDrawEvent read FOnDraw write FOnDraw;
    property OnPrinterSetupChange: TNotifyEvent read FOnPrinterSetupChange write FOnPrinterSetupChange;
    property OnPrint: TNotifyEvent read FOnPrint write FOnPrint;
    property OnPreviewOpen: TNotifyEvent read FOnPreviewOpen write FOnPreviewOpen;
    property OnPreviewClose: TNotifyEvent read FOnPreviewClose write FOnPreviewClose;
  end;

function MM_PXLS(MM: Integer; Index: Integer): Integer;
function PXLS_MM(PXLS: Integer; Index: Integer): Integer;
{function MM_PXLS_X(MM: Integer): Integer;
function MM_PXLS_Y(MM: Integer): Integer;
function PXLS_MM_X(PXLS: Integer): Integer;
function PXLS_MM_Y(PXLS: Integer): Integer;}

implementation

uses Utils;

{$R *.DFM}

function MM_PXLS(MM: Integer; Index: Integer): Integer;
begin
  Result := Round(MM *
    Windows.GetDeviceCaps(Printer.Handle, Index) / 25.412
  );
end;

function PXLS_MM(PXLS: Integer; Index: Integer): Integer;
begin
  Result := Round(PXLS * 25.412 /
    Windows.GetDeviceCaps(Printer.Handle, Index) + 0.5
  );
end;

{function MM_PXLS_X(MM: Integer): Integer;
begin
  Result := MM_PXLS(MM, LOGPIXELSX)
end;

function MM_PXLS_Y(MM: Integer): Integer;
begin
  Result := MM_PXLS(MM, LOGPIXELSY)
end;

function PXLS_MM_X(PXLS: Integer): Integer;
begin
  Result := PXLS_MM(PXLS, LOGPIXELSX)
end;

function PXLS_MM_Y(PXLS: Integer): Integer;
begin
  Result := PXLS_MM(PXLS, LOGPIXELSY)
end;}

{ TRptButton }

constructor TRptButton.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := [csSetCaption, csCaptureMouse, csOpaque];
  FBtnStates := [bsDrawFocus, bsShowCaption, bsFrameRect];
  Height := 26;
  Width  := 76;
  ParentFont := True;
  ParentColor := True;
  TabStop := True;
end;

procedure TRptButton.CMDialogChar(var Message: TCMDialogChar);
begin
  with Message do
    if IsAccel(CharCode, Caption) and Enabled and Visible and (Parent <> nil) and Parent.Showing then
    begin
      Click;
      Result := 1;
    end else
      inherited;
end;

procedure TRptButton.CMDialogKey(var Message: TCMDialogKey);
begin
  with Message do
    if
      (
        (CharCode = VK_RETURN) and
        (ibsFocused in InternalBtnState)
      ) and
      (KeyDataToShiftState(Message.KeyData) = []) and CanFocus then
    begin
      Click;
      Result := 1;
    end else
      inherited;
end;

procedure TRptButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

{procedure TRptButton.CMFocusChanged(var Message: TCMFocusChanged);
begin
  with Message do
    if (Sender is TRptButton) then
      if Sender = Self then
        InternalBtnState := InternalBtnState + [ibsActive, ibsFocused]
      else
        InternalBtnState := InternalBtnState - [ibsActive, ibsFocused, ibsSpace]
    else
      InternalBtnState := InternalBtnState - [ibsActive, ibsFocused, ibsSpace];

  inherited;
end;}

procedure TRptButton.CMFontChanged(var Message: TMessage);
begin
  Invalidate;
  inherited;
end;

procedure TRptButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if
    ( not (ibsMouseInControl in InternalBtnState)
    ) and Enabled then
      InternalBtnState := InternalBtnState + [ibsMouseInControl];
end;

procedure TRptButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (ibsMouseInControl in InternalBtnState) and Enabled then
    InternalBtnState := InternalBtnState - [ibsMouseInControl];
end;

procedure TRptButton.CMSysColorChange(var Message: TMessage);
begin
  Invalidate;
  inherited;
end;

procedure TRptButton.CMTextChanged(var Message: TMessage);
begin
  Invalidate;
  inherited;
end;

procedure TRptButton.CNCommand(var Message: TWMCommand);
begin
 inherited;
 if Message.NotifyCode = BN_CLICKED then Click;
end;

procedure TRptButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_SPACE) and (not (ibsSpace in InternalBtnState)) then
    InternalBtnState := InternalBtnState + [ibsSpace];
end;

procedure TRptButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_SPACE) and (ibsSpace in InternalBtnState) then
  begin
    InternalBtnState := InternalBtnState - [ibsSpace];
    Click;
  end;
end;

procedure TRptButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and Enabled then
    InternalBtnState := InternalBtnState + [ibsPressed];
end;

procedure TRptButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  DoClick: Boolean;
begin
  inherited;
  if (ibsPressed in InternalBtnState) then
  begin
    InternalBtnState := InternalBtnState - [ibsPressed];
    DoClick := (X >= 0) and (X < ClientWidth) and (Y >= 0) and (Y <= ClientHeight);
    if DoClick then Click;
  end;
end;

procedure TRptButton.Paint;
const
  _FlagsText: Longint = (DT_CENTER or DT_NOCLIP or DT_END_ELLIPSIS);
  _FlagsTextEx: array[Boolean] of Longint =
    (DT_VCENTER or DT_SINGLELINE, DT_WORDBREAK);
var
  ARect: TRect;
begin
  ARect := GetClientRect;

  with Canvas do
  begin
    if (Enabled and
      (
        (ibsFocused in InternalBtnState) or
        (ibsMouseInControl in InternalBtnState)
      )
    ) then
    begin
      if (bsDown in BtnStates) or
        (ibsSpace in InternalBtnState) or
        (ibsPressed in InternalBtnState) then
      begin
        Pen.Color := clBtnShadow;
        Brush.Color := GetLightColor(clBtnFace, 30);
        Rectangle(ARect);
        InflateRect(ARect, -1, -1);
      end else
      begin
        Pen.Color := clBtnShadow;
        Brush.Color := GetShadeColor(clBtnFace, 10);
        Rectangle(ARect);
        InflateRect(ARect, -1, -1);
      end
    end else
    begin
     if (bsDown in BtnStates) then {}
      begin
       Pen.Color := clBtnShadow;
       Brush.Color := GetLightColor(clBtnFace, 50);
       Rectangle(ARect);
       InflateRect(ARect, -1, -1);
      end else
      begin
        if (bsFrameRect in BtnStates) then
          Pen.Color := clBtnShadow
        else
          Pen.Color := clBtnFace;
        Brush.Color := clBtnFace;
        Rectangle(ARect);
        InflateRect(ARect, -1, -1); {}
      end;
    end;
     
    if (bsShowCaption in BtnStates) then
    begin
      Brush.Style := bsClear;


      if not Enabled then
       Font.Color := clBtnShadow else
      If Enabled then 
       Font.Color := clblack;


        Windows.DrawText(Handle, PChar(Caption), Length(Caption), ARect,
          _FlagsText or _FlagsTextEx[bsMultiline in BtnStates]);
        Application.ProcessMessages;  
    end
  end
end;

procedure TRptButton.SetInternalBtnState(const Value: TInternalBtnState);
begin
  if FInternalBtnState = Value then Exit;
  FInternalBtnState := Value;
  Invalidate;
end;

procedure TRptButton.WMKillFocus(var Message: TMessage);
begin
  InternalBtnState := InternalBtnState - [ibsFocused, ibsSpace];
  inherited;
end;

procedure TRptButton.WMSetFocus(var Message: TMessage);
begin
  InternalBtnState := InternalBtnState + [ibsFocused];
  inherited;
end;

procedure TRptButton.SetBtnStates(const Value: TBtnStates);
begin
  if FBtnStates = Value then Exit;
  FBtnStates := Value;
  Invalidate;
end;

{ TPageControl }

constructor TPageControl.Create(AOwner: TComponent);
begin
  inherited;
  FBmp := TBitmap.Create;
  Color := clWhite;
  Visible := False;
end;

destructor TPageControl.Destroy;
begin
  FBmp.Free;
  inherited;
end;

procedure TPageControl.Paint;
var
  R: TRect;
begin

  R := Canvas.ClipRect;
  Windows.BitBlt(Canvas.Handle, R.Left, R.Top, R.Right - R.Left,
    R.Bottom - R.Top, FBmp.Canvas.Handle, R.Left, R.Top, cmSrcCopy)
  //Canvas.CopyRect(Canvas.ClipRect, FBmp.Canvas
  //Canvas.Draw(0, 0, FBmp)
end;

procedure TPageControl.UpdatePage(AWidth, AHeight: Integer);
begin

  with FBmp do
    if (Width <> AWidth) or (Height <> AHeight) then
    begin
      {FBmp.Free;
      FBmp := TBitmap.Create;}
      Width := AWidth; Height := AHeight;
    end;
  PaintPage;
end;

procedure TPageControl.PaintPage;
begin

  with FBmp, Canvas do
  begin
    SetMapMode({Canvas.}Handle, mm_AnIsotropic);
    SetWindowExtEx({Canvas.}Handle, Printer.PageWidth, Printer.PageHeight, nil);
    SetViewportExtEx({Canvas.}Handle, Width, Height, nil);
    SetViewportOrgEx({Canvas.}Handle, 0, 0, nil);
    {Brush.Style := bsSolid;
    Brush.Color := clWhite;
    FillRect(Rect(0, 0, Width, Height));}
    Brush.Style := bsSolid;
    Brush.Color := clWhite;
    FillRect(Rect(0, 0, Printer.PageWidth, Printer.PageHeight));
    Font.PixelsPerInch := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
    if Font.PixelsPerInch > GetDeviceCaps(Printer.Handle, LOGPIXELSY) then
      Font.PixelsPerInch := GetDeviceCaps(Printer.Handle, LOGPIXELSY);
  end;
  if Assigned(FPreviewer) then
    with FPreviewer do
      if Assigned(PrintService) then
        PrintService.DoDraw({Self{.}FBmp.Canvas, PageIndex, dtPreview);
end;

{ TPreviewForm }

constructor TPreviewForm.Create(AOwner: TComponent);

  procedure InitMainMenu;

    procedure NewItem(Parent: TMenuItem; Items: array of TMenuList);
    const
      miSeps = [mi_sep1];
    var
      I: Byte;
    begin
      for I := Low(Items) to High(Items) do
      begin
        MenuItems[Items[I]] := TMenuItem.Create(Self);
        if Items[I] in miSeps then MenuItems[Items[I]].Caption := cLineCaption;
        Parent.Add(MenuItems[Items[I]]);
      end;
    end;

    procedure MenuItemAttr(MenuItem: TMenuItem; const ACaption: String;
      AOnExecute: TNotifyEvent);
    begin
      with MenuItem do
      begin
        Caption := ACaption;
        RadioItem := True;
        OnClick := AOnExecute;
      end
    end;

  begin
    FZoomMenu := TPopupMenu.Create(Self);

    NewItem(FZoomMenu.Items, [MI_10, MI_25, MI_50, MI_75, MI_100, MI_150,
      MI_200, mi_sep1, MI_WIDTH, MI_FULL]);

    MenuItemAttr(MenuItems[MI_10], '10%', ZoomExecute);
    MenuItemAttr(MenuItems[MI_25], '25%', ZoomExecute);
    MenuItemAttr(MenuItems[MI_50], '50%', ZoomExecute);
    MenuItemAttr(MenuItems[MI_75], '75%', ZoomExecute);
    MenuItemAttr(MenuItems[MI_100], '100%', ZoomExecute);
    MenuItemAttr(MenuItems[MI_150], '150%', ZoomExecute);
    MenuItemAttr(MenuItems[MI_200], '200%', ZoomExecute);
    MenuItemAttr(MenuItems[MI_WIDTH], 'По ширине страницы', ZoomExecute);
    MenuItemAttr(MenuItems[MI_FULL], 'Страница целиком', ZoomExecute);
    MenuItems[MI_FULL].Checked := True;
  end;

type
  TCaptionHint = array[0..1] of String;
  TCaptionHints = record
    vPrev, vNext, vZoom, vPrint, vOptions, vClose: TCaptionHint;
  end;

const
  CCaptionHints: TCaptionHints = (
    vPrev: (
      '&Назад', 'Предыдущая страница'
    );
    vNext: (
      '&Далее', 'Следующая страница'
    );
    vZoom: (
      '&Масштаб', 'Масштаб'
    );
    vPrint: (
      '&Печать', 'Печать'
    );
    vOptions: (
      'На&стройка', 'Настройки принтера'
    );
    vClose: (
      '&Закрыть', 'Закрыть окно предварительного просмотра'
    );
  );

  procedure InitToolBar;
  var
    L: Integer;
    Btn: TToolButton;
  begin
    L := 5;
    for Btn := Low(Btns) to High(Btns) do
    begin
      Btns[Btn] := TRptButton.Create(Self);
      with Btns[Btn] do
      begin
        Left := L;
        Top := 0;
        {BtnStates := [bsDrawFocus, bsShowCaption, bsFrameRect];}
        Inc(L, Width + 5);
      end;
      Btns[Btn].Parent := tbrMain;
    end;
  end;

  procedure ButtonAttr(Sender: TRptButton; const ACaption, AHint: String;
    AOnClick: TNotifyEvent);
  begin
    with Sender do
    begin
      Caption := ACaption;
      Hint := AHint;
      OnClick := AOnClick;
    end;
  end;

begin
  inherited;
  FAfterPrinterSetupDialog := nil;
  FOnFormClose             := nil;
  {imlMain.GetIcon(6, Icon);}
  FViewMode := vmFullPage;
  FPageCount := 0;
  FPageIndex := 1;

  InitMainMenu;
  InitToolbar;
  ButtonAttr(Btns[TB_Prev], CCaptionHints.vPrev[0],
    CCaptionHints.vPrev[1], tbtPrevPageClick);
  ButtonAttr(Btns[TB_Next], CCaptionHints.vNext[0],
    CCaptionHints.vNext[1], tbtNextPageClick);
  ButtonAttr(Btns[TB_Zoom], CCaptionHints.vZoom[0],
    CCaptionHints.vZoom[1], tbtZoomClick);
  ButtonAttr(Btns[TB_Print], CCaptionHints.vPrint[0],
    CCaptionHints.vPrint[1], tbtPrintClick);
  ButtonAttr(Btns[TB_Options], CCaptionHints.vOptions[0],
    CCaptionHints.vOptions[1], tbtPrinterSetupDialogClick);
  ButtonAttr(Btns[TB_Close], CCaptionHints.vClose[0],
    CCaptionHints.vClose[1], tbtCloseClick);

  FPageControl := TPageControl.Create(Self);
  with FPageControl do
  begin
    Left := 8;
    Top := 8;
    Previewer := Self;
    Parent := sbxMain;
  end;
end;

procedure TPreviewForm.UpdatePageSetup;
var
  Scaling: Integer;
begin
  with FPageControl{, Printer} do
  begin
    Visible := False;

    case FViewMode of
      vm200: Scaling := 200;
      vm150: Scaling := 150;
      vm100: Scaling := 100;
      vm75: Scaling := 75;
      vm50: Scaling := 50;
      vm25: Scaling := 25;
      vm10: Scaling := 10;
      vmPageWidth: // по ширине страницы
      begin
        with sbxMain do
        begin
          VertScrollBar.Position := 0;
          HorzScrollBar.Position := 0;
        end;
        Scaling := 1;
        Left := 8;
        Top := 8;
        Width := sbxMain.Width-20-GetSystemMetrics(sm_CXVScroll);
        Height := Width*GetDeviceCaps(Printer.Handle, VertSize) div
          GetDeviceCaps(Printer.Handle, HorzSize);
        with sbxMain do
        begin
          VertScrollBar.Range := FPageControl.Height+16;
          HorzScrollBar.Range := 0;
        end;
      end;
      vmFullPage: // страница целиком
      begin
        Scaling := 1;
        with sbxMain do
        begin
          VertScrollBar.Range := 0;
          HorzScrollBar.Range := 0;
          VertScrollBar.Position := 0;
          HorzScrollBar.Position := 0;
        end;
        Height := sbxMain.ClientHeight-16;
        Width := Height * GetDeviceCaps(Printer.Handle, HorzSize) div
          GetDeviceCaps(Printer.Handle, VertSize);
        if Width>sbxMain.ClientWidth-16 then
        begin
          Width := sbxMain.ClientWidth-16;
          Height := Width * GetDeviceCaps(Printer.Handle, VertSize) div
            GetDeviceCaps(Printer.Handle, HorzSize);
        end;
        Left := (sbxMain.ClientWidth-Width) div 2;
        Top := (sbxMain.ClientHeight-Height) div 2;
      end;
      else Scaling := 1;
    end;

    case FViewMode of
      vm200..vm10:
      begin
        with sbxMain do
        begin
          VertScrollBar.Position := 0;
          HorzScrollBar.Position := 0;
        end;
        
        Left := 8;
        Top := 8;
        Width := Scaling * Printer.PageWidth * PixelsPerInch div
          GetDeviceCaps(Printer.Handle, LOGPIXELSX) div 100;
        Height := Width * GetDeviceCaps(Printer.Handle, VertSize) div
          GetDeviceCaps(Printer.Handle, HorzSize);
        with sbxMain do
        begin
          VertScrollBar.Range := FPageControl.Height+16;
          HorzScrollBar.Range := FPageControl.Width+16;
        end;
      end;
    end;

    {Invalidate;}
    UpdatePage(Width, Height);

    Visible := True;
  end;
end;

procedure TPreviewForm.UpdatePreview;
begin
  {with }FPageControl.Invalidate{ do}
  {begin
    Hide;
    Show;
  end;}
end;

procedure TPreviewForm.SetViewMode(Value: TViewMode);
begin
  if Value <> FViewMode then
  begin
    FViewMode := Value;
    case FViewMode of
      vm200: MenuItems[MI_200].Checked := True;
      vm150: MenuItems[MI_150].Checked := True;
      vm100: MenuItems[MI_100].Checked := True;
      vm75: MenuItems[MI_75].Checked := True;
      vm50: MenuItems[MI_50].Checked := True;
      vm25: MenuItems[MI_25].Checked := True;
      vm10: MenuItems[MI_10].Checked := True;
      vmPageWidth: MenuItems[MI_Width].Checked := True;
      vmFullPage: MenuItems[MI_Full].Checked := True;
    end;
    UpdatePageSetup;
  end;
end;

procedure TPreviewForm.UpdatePreviewer;
begin
  Btns[TB_Prev].Enabled := (PageIndex > 1);
  Btns[TB_Next].Enabled := (PageIndex < PageCount);

//  Btns[TB_Prev].Repaint;
//  Btns[TB_Next].Repaint;

//  Btns[TB_Prev].Visible := (PageIndex > 1);
//  Btns[TB_Next].Visible := (PageIndex < PageCount);

// sendMessage(Btns[TB_Prev].Handle, CM_ENABLEDCHANGED, 0, 0,);
// sendMessage(Btns[TB_Next].Handle, CM_ENABLEDCHANGED, 0, 0,);

  Application.ProcessMessages;
  stbMain.Panels[0].Text :=
    'Страница ' + IntToStr(PageIndex) + ' из ' + IntToStr(PageCount);
end;

procedure TPreviewForm.SetPageCount(Value: Integer);
begin
  if Value < 0{1} then Value := 0{1};

  if Value = PageCount then Exit;

  FPageCount := Value;

  if PageIndex > PageCount then PageIndex := PageCount;

  {if (PageCount > 1) and not stbMain.Visible then
    Height := Height + stbMain.Height
  else
    if (PageCount = 1) and stbMain.Visible then
      Height := Height - stbMain.Height;
  stbMain.Visible := PageCount>1;}


  UpdatePageSetup;
  UpdatePreviewer;
end;

procedure TPreviewForm.SetPageIndex(Value: Integer);
begin
  if Value < 1 then Value := 1;
  if Value > PageCount then Value := PageCount;
  if Value <> FPageIndex then
  begin
    FPageIndex := Value;

    FPageControl.PaintPage;

    {FPageControl.Visible := False;
    with sbxMain do
    begin
      VertScrollBar.Position := 0;
      HorzScrollBar.Position := 0;
    end;}
    UpdatePreview;
    {FPageControl.Visible := True;}

    UpdatePreviewer;
    {FPageControl.PaintPage;
    UpdatePreview;}
  end;
end;

procedure TPreviewForm.Resize;
begin
  UpdatePageSetup;
  inherited;
end;

procedure TPreviewForm.DoClose(var Action: TCloseAction);
begin
  if Assigned(PrintService) then
    with PrintService do
      if Assigned(OnPreviewClose) then OnPreviewClose(Self);
  Action := caFree;
//
  if Assigned(FOnFormClose) then FOnFormClose();
end;

procedure TPreviewForm.ZoomExecute(Sender: TObject);
begin
  with Sender as TMenuItem do
  begin
    Checked := True;
    if Sender = MenuItems[MI_10] then FViewMode := vm10
    else
    if Sender = MenuItems[MI_25] then FViewMode := vm25
    else
    if Sender = MenuItems[MI_50] then FViewMode := vm50
    else
    if Sender = MenuItems[MI_75] then FViewMode := vm75
    else
    if Sender = MenuItems[MI_100] then FViewMode := vm100
    else
    if Sender = MenuItems[MI_150] then FViewMode := vm150
    else
    if Sender = MenuItems[MI_200] then FViewMode := vm200
    else
    if Sender = MenuItems[MI_WIDTH] then FViewMode := vmPageWidth
    else
    if Sender = MenuItems[MI_FULL] then FViewMode := vmFullPage;
    UpdatePageSetup;
  end;
end;

{procedure TPreviewForm.tbtPrintDialogClick(Sender: TObject);
begin
  if Assigned(PrintService) then PrintService.PrintDialog;
end;}

procedure TPreviewForm.tbtPrinterSetupDialogClick(Sender: TObject);
begin
  if Assigned(PrintService) then PrintService.PrinterSetupDialog;
 if Assigned(FAfterPrinterSetupDialog) then FAfterPrinterSetupDialog;
end;

procedure TPreviewForm.tbtPrintClick(Sender: TObject);
begin
  if Assigned(PrintService) then
   PrintService.Print(PageIndex);
end;

function TPreviewForm.IsShortCut(var Message: TWMKey): Boolean;
begin   
  with sbxMain do
  begin
    with VertScrollBar do
      case Message.CharCode of
        VK_UP:
        begin
          if (GetKeyState(VK_CONTROL) < 0) then
            Position := Position - ClientHeight + Increment
          else
            Position := Position - Increment;
          Result := True;
          Exit;
        end;
        VK_DOWN:
        begin
          if (GetKeyState(VK_CONTROL) < 0) then
            Position := Position + ClientHeight - Increment
          else
            Position := Position + Increment;
          Result := True;
          Exit;
        end;
        VK_HOME:
        begin
          if (GetKeyState(VK_CONTROL) < 0) then
            PageIndex := 0
          else
            Position := 0;
          Result := True;
          Exit;
        end;
        VK_END:
        begin
          if (GetKeyState(VK_CONTROL) < 0) then
            PageIndex := PageCount
          else
            Position := Range;
          Result := True;
          Exit;
        end;
      end;

    with HorzScrollBar do
      case Message.CharCode of
        VK_LEFT:
        begin
          if (GetKeyState(VK_CONTROL) < 0) then
            Position := 0
          else
            Position := Position - Increment;
          Result := True;
          Exit;
        end;
        VK_RIGHT:
        begin
          if (GetKeyState(VK_CONTROL) < 0) then
            Position := Range
          else
            Position := Position + Increment;
          Result := True;
          Exit;
        end;
      end;

    case Message.CharCode of
      VK_PRIOR:
      begin
        PageIndex := Pred(PageIndex);
        Result := True;
        Exit;
      end;
      VK_NEXT:
      begin
        PageIndex := Succ(PageIndex);
        Result := True;
        Exit;
      end;
    end;
  end;

  Result := inherited IsShortCut(Message);
end;

procedure TPreviewForm.tbtPrevPageClick(Sender: TObject);
begin
  PageIndex := Pred(PageIndex);
{  if PageIndex = 2 then
   printer.Orientation := poLandscape else
  printer.Orientation := poPortrait;
  UpdatePageSetup; {}
end;

procedure TPreviewForm.tbtNextPageClick(Sender: TObject);
begin
  PageIndex := Succ(PageIndex);
{  if PageIndex = 2 then
   printer.Orientation := poLandscape else
  printer.Orientation := poPortrait;
  UpdatePageSetup; {}
end;

procedure TPreviewForm.tbtZoomClick(Sender: TObject);
var
  P: TPoint;
begin
  P.X  :=  0; P.Y  :=  0;
  with TRptButton(Sender) do
  begin
    P  :=  ClientToScreen(P);
    FZoomMenu.Popup(P.X, P.Y + Height);
  end
end;

procedure TPreviewForm.tbtCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TPreviewForm.WMGetMinMaxInfo(var Msg: TMessage);
begin
  inherited;
  with PMinMaxInfo(Msg.lParam)^.ptMinTrackSize do
  begin
    X := 164;
    Y := 277;
  end;
end;

{ TPrintService }

constructor TPrintService.Create(AOwner: TComponent);
begin
  inherited;// Create(AOwner);
  FPageCount := 0;
  FPreviewerCaption := 'Предварительный просмотр';
  FPrintDialog :=  TPrintDialog.Create(Self);
  FPrinterSetupDialog :=  TPrinterSetupDialog.Create(Self);
  with FPrintDialog do
   Options := Options+[poPageNums];
  {try}
    if Assigned(FOnCreate) then FOnCreate(Self);
  {except
    Application.HandleException(Self);
  end;}
end;

procedure TPrintService.OpenPreview;
begin
  if FPreviewer=nil then
  begin
    FPreviewer := TPreviewForm.Create(Owner);
    FreeNotification(FPreviewer);
    with FPreviewer do
    begin
      PrintService := Self;
      PageCount := Self.PageCount;
      Caption := PreviewerCaption;
      if Assigned(FOnPreviewOpen) then FOnPreviewOpen(Self);
      Show;
    end;
  end
  else
  begin
    if IsIconic(FPreviewer.Handle) then
      ShowWindow(FPreviewer.Handle, sw_Restore);
    BringWindowToTop(FPreviewer.Handle);
  end;
end;

procedure TPrintService.ClosePreview;
begin
  if Assigned(Previewer) then Previewer.Close;
end;

procedure TPrintService.DoDraw(Canvas: TCanvas; PageNumber: Integer;
    DrawTarget: TDrawTarget);
begin
  if Assigned(OnDraw) then
    OnDraw(Self, Canvas, PageNumber, DrawTarget);
end;

procedure TPrintService.Print(Page : Integer);
 // var
 //  Page: Integer;
begin
  if PageCount = 0 then Exit;

  if Assigned(FOnPrint) then FOnPrint(Self);

  with Printer do
  begin
    BeginDoc;
    {for Page := 1 to PageCount do
    begin {}
      DoDraw(Canvas, Page, dtPrint);
      // if Page < PageCount then NewPage;
    // end;
    EndDoc;
  end;
end;

procedure TPrintService.PrintDialog(Page : Integer);
begin
  with FPrintDialog do
  begin
    MinPage := 1;
    MaxPage := PageCount;
    FromPage := 1;
    ToPage := PageCount;
    if Execute then
    begin
      if Assigned(Previewer) then Previewer.UpdatePageSetup;
      if Assigned(FOnPrinterSetupChange) then FOnPrinterSetupChange(Self);
      Print(Page);
      (*if Assigned(FOnPrint) then FOnPrint(Self);
      with Printer do
      begin
        BeginDoc;
        if Assigned(FOnDraw) then
          for Page := FromPage to ToPage do
          begin
            FOnDraw(Self, Canvas, Page, dtPrint);
            if Page<ToPage then NewPage;
          end;
        EndDoc;
      end;*)
    end;
  end;
end;

procedure TPrintService.PrinterSetupDialog;
begin
  with FPrinterSetupDialog do
    if Execute then
    begin
      if Assigned(Previewer) then Previewer.UpdatePageSetup;
      if Assigned(FOnPrinterSetupChange) then FOnPrinterSetupChange(Self);
    end;
end;

procedure TPrintService.UpdatePreview;
begin
  if Assigned(Previewer) then Previewer.UpdatePreview;
end;

procedure TPrintService.SetPreviewerCaption(Value: string);
begin
  if Value <> FPreviewerCaption then
  begin
    FPreviewerCaption := Value;
    if Assigned(Previewer) then Previewer.Caption := PreviewerCaption;
  end;
end;

procedure TPrintService.SetPageCount(Value: Integer);
begin
  if Value < 0{1} then Value := 0{1};
  if Value <> PageCount then
  begin
    FPageCount := Value;
    if Assigned(Previewer) then Previewer.PageCount := PageCount;
  end;
end;

procedure TPrintService.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (
    (Operation = opRemove) and (AComponent = FPreviewer)
  ) then FPreviewer := nil;
  inherited;
end;

function TPrintService.PageSizeX: Integer;
begin
  {Printer.State(psHandleIC);}
  Result := GetDeviceCaps(Printer.Handle, HorzSize);
end;

function TPrintService.PageSizeY: Integer;
begin
  Result := GetDeviceCaps(Printer.Handle, VertSize);
end;

end.
