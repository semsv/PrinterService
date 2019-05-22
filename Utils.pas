unit Utils;

interface

uses Windows, Messages, SysUtils, Graphics;

function  Min(A, B: Longint): Longint;
function  Max(A, B: Longint): Longint;

function  GetDateTime: TSystemTime;
function  DateTimeToSystemTime(DateTime: TDateTime): TSystemTime;
function DateToStr(const SystemTime: TSystemTime;
  const DateFormat: String = ''): String;
function TimeToStr(const SystemTime: TSystemTime;
  const TimeFormat: String = ''): String;
function DateTimeToStr(const SystemTime: TSystemTime;
  const DateTimeFormat: String = ''): String; overload;
function DateTimeToStr(const DateTime: TDateTime;
  const DateTimeFormat: String = ''): String; overload;

function GetLightColor(Color: TColor; Light: Byte) : TColor;
function GetShadeColor(Color: TColor; Shade: Byte) : TColor;

procedure TextOutEx(DC: HDC; pText: PChar; var prc: TRect; iFlags: Longint);

const
  { TextOutEx() Format Flags }
  TOE_TOP = 0;
  TOE_LEFT = 0;
  TOE_CENTER = 1;
  TOE_RIGHT = 2;
  TOE_VCENTER = 4;
  TOE_BOTTOM = 8;
  TOE_WORDBREAK = $10;
  TOE_SINGLELINE = $20;
  TOE_JUSTIFIED = $40;
  TOE_CALCRECT = $100;
  TOE_TRANSPARENT = $800;
  {TA_TABSTOP = $80;
  {TA_LEFT       = 0;
  TA_RIGHT      = 1;
  TA_CENTER     = 2;
  TA_JUSTIFIED  = 3;}

implementation

type

  TRGB = packed record
    R, G, B: Byte;
  end;

function Min(A, B: Longint): Longint;
begin
  if A < B then Result := A
  else Result := B;
end;

function Max(A, B: Longint): Longint;
begin
  if A < B then Result := B
  else Result := A;
end;

function GetRGB(Color: TColor): TRGB;
var
  iColor: TColor;
begin
  iColor := ColorToRGB(Color);
  Result.R := GetRValue(iColor);
  Result.G := GetGValue(iColor);
  Result.B := GetBValue(iColor);
end;

function GetLightColor(Color: TColor; Light: Byte) : TColor;
var
  fFrom: TRGB;
begin
  FFrom := GetRGB(Color);

  Result := RGB(
    Round(FFrom.R + (255 - FFrom.R) * (Light / 100)),
    Round(FFrom.G + (255 - FFrom.G) * (Light / 100)),
    Round(FFrom.B + (255 - FFrom.B) * (Light / 100))
  );
end;

function  GetShadeColor(Color: TColor; Shade: Byte) : TColor;
var
  fFrom: TRGB;
begin
  FFrom := GetRGB(Color);

  Result := RGB(
    Max(0, FFrom.R - Shade),
    Max(0, FFrom.G - Shade),
    Max(0, FFrom.B - Shade)
  );
end;

{
  TextOutEx - сырой вариант вывода текта на канву
}
procedure TextOutEx(DC: HDC; pText: PChar; var prc: TRect; iFlags: Longint);

  function NextWord(Str: PChar): Integer;
  begin
    Result := 0;
    while not (Str^ in [#0, #13, #32, {';', ':', ',', '.',}
       '[', {']',} '(', {')'} '\']) do
    begin
      Inc(Result);
      Inc(Str);
    end;
  end;

var
  FShortLine: Boolean;
  LineCount, LineHeight: Integer;
  xStart, yStart, iSpaceCount, iBreakCount: Integer;
  pBegin, pEnd: PChar;
  size: TSize;

  procedure BeginLine;
  begin
    iBreakCount := 0;
    if (IFlags and TOE_JUSTIFIED) <> 0 then {если выравнивание по ширине}
      while (pText^ = ' ') do Inc(pText); {то лишние пробелы
      в начале строки нам не нужны}
    pBegin := pText; {запоминаем начало строки}
    pEnd := pText; {запоминаем начало строки}
  end;

  procedure NeLine;
  begin
    if LineCount > 0 then Inc(yStart, LineHeight);
    Inc(LineCount);
  end;

  procedure LineOut;
  begin
    GetTextExtentPoint32 (dc, pBegin, (pEnd - pBegin), Size);

    if (iFlags and TOE_LEFT) <> 0 then xStart := prc.left
    else
    if (iFlags and TOE_RIGHT) <> 0 then xStart := prc.right - size.cx
    else
    if (iFlags and TOE_CENTER) <> 0 then
        xStart := (prc.right + prc.left - size.cx) div 2
    else
    if (iFlags and TOE_JUSTIFIED) <> 0 then
    begin
      if (not FShortLine) and (iBreakCount > 0) then
        SetTextJustification(dc, prc.right - prc.left - size.cx,
          iBreakCount);
      FShortLine := False;
    end;

    if (iFlags and TOE_TRANSPARENT) <> 0 then SetBkMode(DC, TRANSPARENT);

    TextOut(dc, xStart, yStart, pBegin, (pEnd - pBegin));

    SetTextJustification(DC, 0, 0); // обнуляем установки выравнивания
  end;

var
  Bool: Boolean;
begin
  Bool := True;
  xStart := prc.Left;
  LineCount := 0;
  GetTextExtentPoint32 (dc, 'Wg', 2, Size);
  LineHeight := Size.cy;
  yStart := prc.Top;
  if ( (IFlags and TOE_WORDBREAK) = 0 ) then
    if ( (IFlags and TOE_VCENTER) <> 0 ) then
      yStart := prc.Top + (prc.Bottom - prc.Top - LineHeight) div 2;

  //  pText := PChar(Strings[I]); {получаем новую строку}

  {if (pText^ = #0) then NewLine
  else}
  if ( (iFlags and TOE_CALCRECT) <> 0 ) and
    ( (IFlags and TOE_WORDBREAK) = 0 ) then
  begin
    while (pText^ <> #0) do {бежим по всей строке} Inc(pText);
    GetTextExtentPoint32(dc, pBegin, (pText - pBegin), Size);
    prc.Right := Size.cx;
    prc.Bottom := LineHeight;
  end else
  if not (
    ( (IFlags and TOE_JUSTIFIED) <> 0 ) or
    ( (IFlags and TOE_WORDBREAK) <> 0 )
  ) then
  begin
    BeginLine; {начинаем новую строку}

    while (pText^ <> #0) do {бежим по всей строке}
    begin
      GetTextExtentPoint32(dc, pBegin, (pText - pBegin), Size);
      if (Size.cx >= (prc.Right - prc.Left)) then Break;
      Inc(pText);
    end;

    pEnd := pText; {запоминаем начало строки}
    NeLine; LineOut;
  end else
  begin
    BeginLine; {начинаем новую строку}

    while Bool and (pText^ <> #0) do
    begin  {бежим по всей строке}

      iSpaceCount := 0;
      while (pText^ <> #0) and (pText^ in [#32, '[', {']',} '(', {')',} '/']) do
      begin
        if (
          ( (iFlags and TOE_CALCRECT) = 0 ) and
          ( (IFlags and TOE_JUSTIFIED) <> 0 ) and (pText^ = #32)
        ) then
          Inc(iSpaceCount);

        Inc(pText);
      end;

      Inc(pText, NextWord(pText)); // перескакиваем через слово

      {if (pText^ in [',', '.', ';', ':']) then // точки, запятые не разделяются со словом
        while (pText^ <> #0) and (pText^ in [',', '.', ';', ':']) do Inc(pText);}

      if ( (IFlags and TOE_WORDBREAK) <> 0 ) then
        GetTextExtentPoint32(dc, pBegin, (pText - pBegin), Size); {получаем
        координаты текущей позиции}

      if (
        ( (IFlags and TOE_WORDBREAK) <> 0 ) and
        (Size.cx >= (prc.Right - prc.Left))
      ) then {если текущая позиция
      выходит за границы Rect, то надо вписати то что вмещается и
      перейти на новую строку}
      begin
        NeLine;
        if ( (iFlags and TOE_CALCRECT) = 0 ) then LineOut;
        pText := pEnd;
        BeginLine; {начинаем новую строку}
      end else
      if (pText^ = #13) then // перенос строки и перевод каретки
      begin
        Inc(iBreakCount, iSpaceCount);
        FShortLine := True;
        pEnd := pText;
        NeLine;
        if ( (iFlags and TOE_CALCRECT) = 0 ) then LineOut;
        Inc(pText);
        if (pText^ = #10) then Inc(pText);
        BeginLine; {начинаем новую строку}
      end else
        begin
          Inc(iBreakCount, iSpaceCount);
          pEnd := pText;
        end;

      Bool := ( (iFlags and TOE_CALCRECT) <> 0 ) or
        (yStart < prc.Bottom);
    end;

    if Bool and {(pText^ = #0)}(pBegin <> pEnd) then
    begin
      NeLine;
      if ( (iFlags and TOE_CALCRECT) = 0 ) then
      begin
        FShortLine := True;
        LineOut;
      end;
    end;
    if ( (iFlags and TOE_CALCRECT) <> 0 ) then prc.Bottom := LineHeight * LineCount;
  end;
end;

function GetDateTime: TSystemTime;
begin
  Windows.GetLocalTime(Result);
end;

function DateTimeToSystemTime(DateTime: TDateTime): TSystemTime;
begin
  SysUtils.DateTimeToSystemTime(DateTime, Result);
end;

function DateToStr(const SystemTime: TSystemTime;
  const DateFormat: String = ''): String;
const
  _Flags: array[Boolean] of LongWord = (0, DATE_SHORTDATE);
var
  _DateFormat: array[Boolean] of PChar;
  DateBufferLength: Longint;
  DateBuffer: String;
begin
  _DateFormat[False] := PChar(DateFormat);
  _DateFormat[True] := nil;

  DateBufferLength :=
    GetDateFormat(LOCALE_USER_DEFAULT, _Flags[DateFormat = ''],
      @SystemTime, _DateFormat[DateFormat = ''], nil, 0
    );

  SetLength(DateBuffer, DateBufferLength - 1);
  //DateBuffer[DateBufferLength] := #0;

  GetDateFormat(LOCALE_USER_DEFAULT, _Flags[DateFormat = ''],
    @SystemTime, _DateFormat[DateFormat = ''], PChar(DateBuffer),
    DateBufferLength
  );

  Result := DateBuffer;
end;

function TimeToStr(const SystemTime: TSystemTime;
  const TimeFormat: String = ''): String;
const
  _Flags: array[Boolean] of LongWord = (0, LOCALE_NOUSEROVERRIDE);
var
  _TimeFormat: array[Boolean] of PChar;
  TimeBufferLength: Longint;
  TimeBuffer: String;
begin
  _TimeFormat[False] := PChar(TimeFormat);
  _TimeFormat[True] := nil;

  TimeBufferLength :=
    GetTimeFormat(LOCALE_USER_DEFAULT, _Flags[TimeFormat = ''],
      @SystemTime, _TimeFormat[TimeFormat = ''], nil, 0
    );

  SetLength(TimeBuffer, TimeBufferLength - 1);
  //TimeBuffer[TimeBufferLength] := #0;

  GetTimeFormat(LOCALE_USER_DEFAULT, _Flags[TimeFormat = ''],
    @SystemTime, _TimeFormat[TimeFormat = ''], PChar(TimeBuffer),
    TimeBufferLength
  );

  Result := TimeBuffer;
end;

function DateTimeToStr(const SystemTime: TSystemTime;
  const DateTimeFormat: String = ''): String;
begin
  if DateTimeFormat = '' then
    Result := DateToStr(SystemTime, DateTimeFormat) + ' ' +
      TimeToStr(SystemTime, DateTimeFormat)
  else
    Result := TimeToStr(SystemTime,
      DateToStr(SystemTime, DateTimeFormat)
    );
end;

function DateTimeToStr(const DateTime: TDateTime;
  const DateTimeFormat: String = ''): String;
begin
  Result := DateTimeToStr(
    DateTimeToSystemTime(DateTime), DateTimeFormat
  );
end;

end.

