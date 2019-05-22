{*****************************************************************}
{                                                                 }
{                 TRyPrintService для Delphi. Пилотный вариант.   }
{                  © 2002 Румянцев Алексей                        }
{                                                                 }
{ Для TRyPrintService можно дать следующее определение: буффер    }
{ всего готовящегося к выводу на печать.                          }
{                                                                 }
{*****************************************************************}
{                                                                 }
{ Специально для Королевства Дельфи http://www.delphikingdom.com  }
{                                                                 }
{*****************************************************************}
{                                                                 }
{ Лицензионное соглашение: AS IS                                  }
{                                                                 }
{*****************************************************************}

unit RyPrnServ;

interface

uses Windows, SysUtils, Messages, Classes, Graphics, Controls, Forms,
  Printers, PrnServ, RySwapStream;

type

  TRptObject = class(TObject)
  private
    FHeight: Integer;
    FLeft: Integer;
    FWidth: Integer;
    FTop: Integer;
    FObjId: Integer;
  protected
    procedure Paint(Canvas: TCanvas); virtual;
    procedure LoadParams(Stream: TStream); virtual;
    procedure SaveParams(Stream: TStream); virtual;
  public
    constructor Create; virtual;
    procedure ClearParams; virtual;
    procedure Print(Canvas: TCanvas; Stream: TStream); virtual;
    property ObjId: Integer read FObjId write FObjId;
    property Left: Integer read FLeft write FLeft;
    property Top: Integer read FTop write FTop;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
  end;

  TRptLine = class(TRptObject)
  private
    FPenColor: TColor;
    FPenStyle: Longint;
  protected
    procedure Paint(Canvas: TCanvas); override;
    procedure LoadParams(Stream: TStream); override;
    procedure SaveParams(Stream: TStream); override;
  public
    constructor Create; override;
    procedure ClearParams; override;
    property PenStyle: Longint read FPenStyle write FPenStyle;
    property PenColor: TColor read FPenColor write FPenColor;
  end;

  TRptRect = class(TRptObject)
  private
    FBkColor: TColor;
    FFrColor: TColor;
    FBrushStyle: Longint;
  protected
    procedure Paint(Canvas: TCanvas); override;
    procedure LoadParams(Stream: TStream); override;
    procedure SaveParams(Stream: TStream); override;
  public
    constructor Create; override;
    procedure ClearParams; override;
    property BrushStyle: Longint read FBrushStyle write FBrushStyle;
    property FrColor: TColor read FFrColor write FFrColor;
    property BkColor: TColor read FBkColor write FBkColor;
  end;
       
  TRptGraphic = class(TRptObject)
  private
    FStretch: Boolean;
  protected
    procedure LoadParams(Stream: TStream); override;
    procedure SaveParams(Stream: TStream); override;
  public
    procedure ClearParams; override;
    property Stretch: Boolean read FStretch write FStretch;
  end;

  TRptBitmap = class(TRptGraphic)
  private
    FStretch: Boolean;
    FBitmap: TBitmap;
  protected
    procedure Paint(Canvas: TCanvas); override;
    procedure LoadParams(Stream: TStream); override;
    procedure SaveParams(Stream: TStream); override;
  public
    constructor Create; override;
    procedure Print(Canvas: TCanvas; Stream: TStream); override;
    procedure ClearParams; override;
    property Stretch: Boolean read FStretch write FStretch;
    property Bitmap: TBitmap read FBitmap write FBitmap;
  end;

  TRptCustomEdit = class(TRptObject)
  private
    FTextFlags: Longint;
    FText: String;
    FBkColor: TColor;
    FFontColor: TColor;
    FFontStyle: Integer;
    FFontSize: Integer;
    FFontName: String;
    FTextAngle : WORD;
  protected
    procedure LoadParams(Stream: TStream); override;
    procedure Paint(Canvas: TCanvas); override;
    procedure SaveParams(Stream: TStream); override;
  public
    procedure ClearParams; override;
    property TextFlags: Longint read FTextFlags write FTextFlags;
    property Text: String read FText write FText;
    property TextAngle : WORD read FTextAngle write FTextAngle;
    property FontName: String read FFontName write FFontName;
    property FontSize: Integer read FFontSize write FFontSize;
    property FontStyle: Integer read FFontStyle write FFontStyle;
    property FontColor: TColor read FFontColor write FFontColor;
    property BkColor: TColor read FBkColor write FBkColor;
  end;

  TRptEdit = class(TRptCustomEdit)
  private
  protected
  public
    constructor Create; override;
  end;

  TRptMemo = class(TRptCustomEdit)
  private
  protected
  public
    constructor Create; override;
  end;

  TRptHeader = packed record
    vVersion: Integer;
    vPageCount: Integer;
    vTitle: array[0..49] of Char;
    vDirt: array[0..255 - 1 - SizeOf(Integer) - SizeOf(Integer) - 50] of Char;
  end;

  TPageHeader = packed record
    vRptObjCount: Integer;
    vNextPage: Integer;
    vDirt: array[0..32 - 1 - SizeOf(Integer) -
      SizeOf(Integer)] of Char;
  end;

  TRyPrintService = class(TPrintService)
  private
    FNewDocument, FNewPage: Boolean;
    FStreamViewer, FFileStreamViewer: Boolean;
    FPageHeader: TPageHeader;
    FRptHeader: TRptHeader;
    FStream: TStream;
    FAPIO    : array [1..100000] of TPrinterOrientation;
    function GoToPage(Index: Integer; var PageHeader: TPageHeader): Boolean;
  protected
    function  GET_PIO(Index : Integer) : TPrinterOrientation;
    procedure SET_PIO(Index : Integer; Value : TPrinterOrientation);
    //
    procedure StartPage;
    procedure EndPage;
    procedure DoDraw(Canvas: TCanvas; PageNumber: Integer;
      DrawTarget: TDrawTarget); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginDoc;
    procedure EndDoc;
    procedure NewPage;
    procedure AddRptObject(RptObject: TRptObject);
    procedure ViewFromStream(SourceStream: TStream);
    procedure ViewFromFile(const FileName: String);
    procedure LoadFromStream(SourceStream: TStream);
    procedure SaveToStream(DestStream: TStream);
    procedure LoadFromFile(const FileName: String);
    procedure SaveToFile(const FileName: String);
    //
    property  Page_Items_Orientation[Index: Integer] : TPrinterOrientation read GET_PIO write SET_PIO;
    //property  Items[Index: Integer]: TRptObject read Get; default;
  end;

function GetFontStyle(AFontStyle: Integer): TFontStyles;
function SetFontStyle(Value: TFontStyles): Integer;

const
  FS_BOLD      = $0001;
  FS_ITALIC    = $0002;
  FS_UNDERLINE = $0004;
  FS_STRIKEOUT = $0008;

var
  RptLine   : TRptLine;
  RptRect   : TRptRect;
  RptEdit   : TRptEdit;
  RptMemo   : TRptMemo;
  RptBitmap : TRptBitmap;

procedure NewRptObject(RptObject: TRptObject);

implementation

uses Utils;

type
  TRptObjects = class(TList)
  protected
    function  Get(Index: Integer): TRptObject;
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    function  ObjById(AObjId: Integer): TRptObject;
    property  Items[Index: Integer]: TRptObject read Get; default;
  end;

const
  ID_RptLine    = 1;
  ID_RptRect    = 2;
  ID_RptEdit    = 3;
  ID_RptMemo    = 4;
  ID_RptBitmap  = 5;

var
  RptObjects: TRptObjects;

procedure NewRptObject(RptObject: TRptObject);
begin
  RptObjects.Add(RptObject);
end;

{ TRptObject }

constructor TRptObject.Create;
begin
  ClearParams;
end;

procedure TRptObject.ClearParams;
begin
  FHeight := 0;
  FLeft := 0;
  FWidth := 0;
  FTop := 0;
end;

procedure TRptObject.Print(Canvas: TCanvas; Stream: TStream);
begin
  //ClearParams;
  LoadParams(Stream);
  Canvas.Font.Charset := 204;
  Paint(Canvas);
end;

procedure TRptObject.Paint(Canvas: TCanvas);
begin

end;

procedure TRptObject.LoadParams(Stream: TStream);
begin
  with Stream do
  begin
    Read(FLeft, SizeOf(Integer));
    Read(FTop, SizeOf(Integer));
    Read(FWidth, SizeOf(Integer));
    Read(FHeight, SizeOf(Integer));
  end
end;

procedure TRptObject.SaveParams(Stream: TStream);
begin
  with Stream do
  begin
    Write(FLeft, SizeOf(Integer));
    Write(FTop, SizeOf(Integer));
    Write(FWidth, SizeOf(Integer));
    Write(FHeight, SizeOf(Integer));
  end
end;

{ TRptObjects }

function TRptObjects.Get(Index: Integer): TRptObject;
begin
  Result := TRptObject(inherited Get(Index))
end;

procedure TRptObjects.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then TObject(Ptr).Free;
  inherited;
end;

function TRptObjects.ObjById(AObjId: Integer): TRptObject;
var
  I, Item: Integer;
begin
  Item := -1;
  for I := 0 to Count - 1 do
    if Get(I).ObjId = AObjId then
    begin
      Item := I;
      Break;
    end;
  if Item > -1 then Result := Get(Item) else Result := nil;
end;

{ TRptLine }

procedure TRptLine.ClearParams;
begin
  inherited;
  FPenColor := clBlack;
  FPenStyle := PS_SOLID;
end;

constructor TRptLine.Create;
begin
  inherited;
  FObjId := ID_RptLine;
end;

procedure TRptLine.LoadParams(Stream: TStream);
begin
  inherited;
  with Stream do
  begin
    Read(FPenColor, SizeOf(TColor));
    Read(FPenStyle, SizeOf(Integer));
  end
end;

procedure TRptLine.Paint(Canvas: TCanvas);
begin
  with Canvas do
  begin
    case PenStyle of
      PS_DASH: Pen.Style := psDash;
      PS_DOT: Pen.Style := psDot;
      PS_DASHDOT: Pen.Style := psDashDot;
      PS_DASHDOTDOT: Pen.Style := psDashDotDot;
      PS_NULL: Pen.Style := psClear;
      PS_INSIDEFRAME: Pen.Style := psInsideFrame;
      else
        Pen.Style := psSolid;
    end;
    Pen.Color := PenColor;
    MoveTo(Left, Top);
    LineTo(Left + Width, Top + Height);
  end
end;

procedure TRptLine.SaveParams(Stream: TStream);
begin
  inherited;
  with Stream do
  begin
    Write(FPenColor, SizeOf(TColor));
    Write(FPenStyle, SizeOf(Integer));
  end
end;

{ TRptRect }

constructor TRptRect.Create;
begin
  inherited;
  FObjId := ID_RptRect;
end;

procedure TRptRect.ClearParams;
begin
  inherited;
  FBkColor := clWhite;
  FFrColor := clBlack;
  BrushStyle := BS_SOLID;
end;

procedure TRptRect.LoadParams(Stream: TStream);
begin
  inherited;
  with Stream do
  begin
    Read(FFrColor, SizeOf(TColor));
    Read(FBkColor, SizeOf(TColor));
    Read(FBrushStyle, SizeOf(Integer));
  end
end;

procedure TRptRect.Paint(Canvas: TCanvas);
begin
  with Canvas do
  begin
    if ( BrushStyle = BS_HOLLOW ) then Brush.Style := bsClear
    else begin
      Brush.Style := bsSolid;
      Brush.Color := BkColor;
    end;
    Pen.Color := FrColor;
    Rectangle(Left, Top, Left + Width, Top + Height);
  end
end;

procedure TRptRect.SaveParams(Stream: TStream);
begin
  inherited;
  with Stream do
  begin
    Write(FFrColor, SizeOf(TColor));
    Write(FBkColor, SizeOf(TColor));
    Write(FBrushStyle, SizeOf(Integer));
  end
end;

{ TRptGraphic }

procedure TRptGraphic.ClearParams;
begin
  inherited;
  FStretch := False;
end;

procedure TRptGraphic.LoadParams(Stream: TStream);
begin
  inherited;
  Stream.Read(FStretch, SizeOf(Boolean));
end;

procedure TRptGraphic.SaveParams(Stream: TStream);
begin
  inherited;
  Stream.Write(FStretch, SizeOf(Boolean));
end;

{ TRptBitmap }

constructor TRptBitmap.Create;
begin
  inherited;
  FObjId := ID_RptBitmap;
end;

procedure TRptBitmap.ClearParams;
begin
  inherited;
  FBitmap := nil;
end;

procedure TRptBitmap.Print(Canvas: TCanvas; Stream: TStream);
begin
  FBitmap := TBitmap.Create;
  try
    inherited
  finally
    FBitmap.Free
  end
end;

procedure TRptBitmap.LoadParams(Stream: TStream);
begin
  inherited;
  FBitmap.LoadFromStream(Stream);
end;

procedure TRptBitmap.SaveParams(Stream: TStream);
begin
  inherited;
  FBitmap.SaveToStream(Stream);
end;

procedure TRptBitmap.Paint(Canvas: TCanvas);
//var
  //R: TRect;
begin
  //R := Rect(FLeft, FTop, FWidth, FHeight);//Canvas.ClipRect;
  if FStretch then
    Windows.StretchBlt(Canvas.Handle, Left, Top, Width - Left,
      Height - Top, FBitmap.Canvas.Handle, 0, 0, FBitmap.Width,
      FBitmap.Height, SRCCOPY)
  else
    Windows.BitBlt(Canvas.Handle, Left, Top, Width - Left,
      Height - Top, FBitmap.Canvas.Handle, 0, 0, SRCCOPY);
end;

{ TCustomEdit }

function GetFontStyle(AFontStyle: Integer): TFontStyles;
begin
  Result := [];
  if (AFontStyle and FS_BOLD) <> 0 then Include(Result, fsBold);
  if (AFontStyle and FS_ITALIC) <> 0 then Include(Result, fsItalic);
  if (AFontStyle and FS_UNDERLINE) <> 0 then Include(Result, fsUnderline);
  if (AFontStyle and FS_STRIKEOUT) <> 0 then Include(Result, fsStrikeOut);
end;

function SetFontStyle(Value: TFontStyles): Integer;
begin
  Result := 0;
  if fsBold in Value then Result := Result or FS_BOLD;
  if fsItalic in Value then Result := Result or FS_ITALIC;
  if fsUnderline in Value then Result := Result or FS_UNDERLINE;
  if fsStrikeOut in Value then Result := Result or FS_STRIKEOUT;
end;

procedure TRptCustomEdit.ClearParams;
begin
  inherited;
  FTextFlags := TOE_LEFT;
  FText := '';
  FBkColor := clWhite;
  FFontName := 'Arial';
  FFontSize := 8;
  FFontStyle := 0;
  FFontColor := clBlack;
  FTextAngle := 0;
end;

procedure TRptCustomEdit.LoadParams(Stream: TStream);
var
  Len: Integer;
begin
  inherited;
  with Stream do
  begin
    Read(FBkColor, SizeOf(TColor));
    Read(Len, SizeOf(Integer));
    SetLength(FFontName, Len);
    Read(Pointer(FFontName)^, Len);
    Read(FFontSize, SizeOf(Integer));
    Read(FFontStyle, SizeOf(Integer));
    Read(FFontColor, SizeOf(TColor));
    Read(FTextFlags, SizeOf(Integer));
    Read(FTextAngle, SizeOf(WORD));
    Read(Len, SizeOf(Integer));
    SetLength(FText, Len);
    Read(Pointer(FText)^, Len);
    {FText := HexToStr(FText);}
  end
end;

procedure TRptCustomEdit.Paint(Canvas: TCanvas);
var
  FRect: TRect;
//
  OldFont, NewFont : hFont;
  lf               : TLogFont;
begin
  with Canvas do
  begin
    //Pen.Color := FrColor;

    if ( (Self.TextFlags and TOE_TRANSPARENT) <> 0 ) then
      Brush.Style := bsClear
    else begin
      Brush.Style := bsSolid;
      Brush.Color := BkColor;
      FillRect(Rect(Left, Top, Left + Width, Top + Height));
    end;

    Font.Color := FontColor;
    Font.Name := FontName;
    Font.Size := FontSize;
    Font.Style := GetFontStyle(FontStyle);
    FRect := Rect(Left, Top, Left + Width, Top + Height);
    //*/////////////////////////////////////////////////////////
      {Создаем описание для нового шрифта.} 
WITH lf, Canvas DO BEGIN


{Устанавливаем текущие для объекта Font параметры, кроме углов.} 
lfHeight := Font.Height; 
lfWidth := 0;
lfEscapement := TextAngle*10; {Угол наклона строки в 0.1 градуса}
lfOrientation := TextAngle*10; {Угол наклона символов в строке в 0.1 градуса}
if fsBold in Font.Style then lfWeight := FW_BOLD 


else lfWeight := FW_NORMAL; 


lfItalic := Byte(fsItalic in Font.Style); 
lfUnderline := Byte(fsUnderline in Font.Style); 
lfStrikeOut := Byte(fsStrikeOut in Font.Style); 
lfCharSet := DEFAULT_CHARSET;
StrPCopy(lfFaceName, Font.Name);
lfQuality := DEFAULT_QUALITY;
lfOutPrecision := OUT_DEFAULT_PRECIS;
lfClipPrecision := CLIP_DEFAULT_PRECIS;
lfPitchAndFamily := DEFAULT_PITCH;


end;
{Создаем новый шрифт}
NewFont := CreateFontIndirect(lf); 
{Выбираем новый шрифт в контекст отображения} 
OldFont := SelectObject(Canvas.Handle, NewFont); 
{Выводим текст на экран ПОД ЗАДАННЫМ УГЛОМ} 
    //*//////////////////////////////////////////////////////
    TextOutEx(Handle, PChar(FText), FRect, FTextFlags);
    //*///////////////////////////////////////////////////////
    {Восстанавливаем в контексте старый шрифт}
    SelectObject(Canvas.Handle, OldFont);
    {Удаляем новый шрифт}
    DeleteObject(NewFont);
    //*////////////////////////////////////////////////////////
    {indows.DrawText(Handle, PChar(Text), Length(Text), FRect, Style);}
  end
end;

procedure TRptCustomEdit.SaveParams(Stream: TStream);
var
  Len: Integer;
begin
  inherited;
  with Stream do
  begin
    Write(FBkColor, SizeOf(TColor));
    Len := Length(FFontName);
    Write(Len, SizeOf(Integer));
    Write(Pointer(FFontName)^, Len);
    Write(FFontSize, SizeOf(Integer));
    Write(FFontStyle, SizeOf(Integer));
    Write(FFontColor, SizeOf(TColor));
    Write(FTextFlags, SizeOf(Integer));
    Write(FTextAngle, SizeOf(WORD));
    {Str := StrToHex(FText);}
    Len := Length(FText);
    Write(Len, SizeOf(Integer));
    Write(Pointer(FText)^, Len);
  end
end;

{ TRptEdit }

constructor TRptEdit.Create;
begin
  inherited;
  FObjId := ID_RptEdit;
end;

{ TRptMemo }

constructor TRptMemo.Create;
begin
  inherited;
  FObjId := ID_RptMemo;
end;

{ TRyPrintService }
function TRyPrintService.GET_PIO(Index : Integer) : TPrinterOrientation;
begin
//
 if (Index >= 1) and
    (Index <= 100000) then
   result := FAPIO[Index];
end;

procedure TRyPrintService.SET_PIO(Index : Integer; Value : TPrinterOrientation);
begin
//
 if (Index >= 1) and
    (Index <= 100000) then
  FAPIO[Index] := Value;
end;

constructor TRyPrintService.Create(AOwner: TComponent);
begin
  inherited;
  FNewDocument      := False;
  FNewPage          := False;
  FStreamViewer     := False;
  FFileStreamViewer := False;
end;

destructor TRyPrintService.Destroy;
begin
  if (FStreamViewer and FFileStreamViewer) or (FStream <> nil) then
    FStream.Free;
  inherited;
end;

function TRyPrintService.GoToPage(Index: Integer;
  var PageHeader: TPageHeader): Boolean;
var
  Bool: Boolean;
  PageIndex: Integer;
begin
  Bool := False;
  PageIndex := 1;
  //
  // printer.Orientation := Page_Items_Orientation[Index];
  //
  with FStream do
  begin
    Position := SizeOf(TRptHeader);
    while (not Bool) and (PageIndex <= FRptHeader.vPageCount) do
    begin
      Read(PageHeader, SizeOf(TPageHeader));
      Bool := Index = PageIndex;
      if not Bool then Position := PageHeader.vNextPage;
      Inc(PageIndex);
    end;
  end;
  
  Result := Bool;
end;

procedure TRyPrintService.DoDraw(Canvas: TCanvas; PageNumber: Integer;
  DrawTarget: TDrawTarget);
var
  I: Integer;
  VObjId: Integer;
  RptObject: TRptObject;
  PageHeader: TPageHeader;
begin
  if not GoToPage(PageNumber, PageHeader) then Exit;

  with FStream do
  begin
    for I := 0 to PageHeader.vRptObjCount - 1 do
    begin
      Read(VObjId, SizeOf(Integer)); {получаем имя объекта}
      RptObject := RptObjects.ObjById(VObjId); {получаем объект по имени}
      if RptObject = nil then Break
      else RptObject.Print(Canvas, FStream); {если объект
      существует, то отправляем его на печать}
      {переходим к следующей ветке}
    end;
  end
end;

procedure TRyPrintService.BeginDoc;
begin
  if FNewDocument then Exit;

  if (FStream <> nil) and FStreamViewer then
    if FFileStreamViewer then FreeAndNil(FStream) else FStream := nil;
  FStreamViewer := False;
  FFileStreamViewer := False;

  if (FStream = nil) then FStream := TRySwapStream.Create;
  FStream.Size := 0;
  FRptHeader.vPageCount := 0;
  FRptHeader.vVersion := 1;
  FRptHeader.vTitle := '';
  FStream.Write(FRptHeader, SizeOf(TRptHeader));
  fPageHeader.vNextPage := SizeOf(TRptHeader);
  FNewDocument := True;
end;

procedure TRyPrintService.EndDoc;
begin
  if not FNewDocument then Exit;
  EndPage;

  with FStream do
  begin
    Position := 0;
    Write(FRptHeader, SizeOf(TRptHeader));
  end;

  FNewDocument := False;
end;

procedure TRyPrintService.NewPage;
begin
  EndPage;
  StartPage;
end;

procedure TRyPrintService.StartPage;
begin
  if (not FNewDocument) or FNewPage then Exit;

  Inc(FRptHeader.vPageCount);
  //fPageHeader.vNextPage := 0;
  //fPageHeader.vPageIndex := FRptHeader.vPageCount;
  fPageHeader.vRptObjCount := 0;
  FStream.Write(FPageHeader, SizeOf(TPageHeader));
  PageCount := PageCount + 1;

  FNewPage := True;
end;

procedure TRyPrintService.EndPage;
var
  Pos: Integer;
begin
  if (not FNewDocument) or (not FNewPage) then Exit;

  with FStream do
  begin
    Pos := Position;
    Position := FPageHeader.vNextPage;{старое значение}
    FPageHeader.vNextPage := Pos;
    Write(FPageHeader, SizeOf(TPageHeader));
    Position := Pos;
  end;

  FNewPage := False;
end;

procedure TRyPrintService.AddRptObject(RptObject: TRptObject);
begin
  if (not FNewDocument) or (not FNewPage) then Exit;

  FStream.Write(RptObject.ObjId, SizeOf(Integer)); {получаем имя объекта}
  RptObject.SaveParams(FStream);
  Inc(FPageHeader.vRptObjCount);
end;

procedure TRyPrintService.LoadFromFile(const FileName: String);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(FileStream)
  finally
    FileStream.Free
  end
end;

procedure TRyPrintService.SaveToFile(const FileName: String);
var
  FileStream: TFileStream;
begin
  if (FStream = nil) then Exit;

  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(FileStream)
  finally
    FileStream.Free
  end
end;

procedure TRyPrintService.LoadFromStream(SourceStream: TStream);
begin
  if (FStream <> nil) and FStreamViewer then
    if FFileStreamViewer then FreeAndNil(FStream) else FStream := nil;
  FStreamViewer := False;
  FFileStreamViewer := False;

  if (FStream = nil) then FStream := TRySwapStream.Create;

  with FStream do
  begin
    Size := SourceStream.Size;
    CopyFrom(SourceStream, 0);
    Position := 0;
    Read(FRptHeader, SizeOf(TRptHeader));
  end;
  PageCount := FRptHeader.vPageCount;
end;

procedure TRyPrintService.SaveToStream(DestStream: TStream);
begin
  if (FStream = nil) then Exit;

  DestStream.CopyFrom(FStream, 0)
end;

procedure TRyPrintService.ViewFromFile(const FileName: String);
begin
  ViewFromStream(
    TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite)
  );
  FFileStreamViewer := True;
end;

procedure TRyPrintService.ViewFromStream(SourceStream: TStream);
begin
  if (FStream <> nil) then
    if FStreamViewer then
      if FFileStreamViewer then FStream.Free else FStream := nil
    else
      FStream.Free;

  FFileStreamViewer := False;
  FStreamViewer := True;
end;

initialization
  RptLine := TRptLine.Create;
  RptRect := TRptRect.Create;
  RptEdit := TRptEdit.Create;
  RptMemo := TRptMemo.Create;
  RptBitmap := TRptBitmap.Create;

  RptObjects := TRptObjects.Create;
  NewRptObject(RptLine);
  NewRptObject(RptRect);
  NewRptObject(RptEdit);
  NewRptObject(RptMemo);
  NewRptObject(RptBitmap);
  
finalization
  RptObjects.Free;

end.
