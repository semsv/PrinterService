{***********************************************************************}
{                         Класс TRySwapSream.                         }
{                                                                       }
{ Версия  : 2.0, 15 апреля 2002 г.                                      }
{ Автор   : Алексей Румянцев.                                           }
{ E-mail  : skitl@mail.ru                                               }
{-----------------------------------------------------------------------}
{ Описание:                                                             }
{   * Реализует и упрощает работу с файлом подкачки.                    }
{   * Может рассматриваться как альтернатива TFileStream, TMemoryStream.}
{-----------------------------------------------------------------------}
{    Специально для Королевства Дельфи http://www.delphikingdom.com     }
{-----------------------------------------------------------------------}
{ Написано на Delphi5. Тестировалось на Win98, WinXP.                   }
{ В случае обнаружения ошибки или несовместимости с другими версиями    }
{ Delphi и Windows, просьба сообщить автору.                            }
{-----------------------------------------------------------------------}
{ Лицензионное соглашение:                                              }
{ * TRySwapStream РАСПРОСТРАНЯЕТСЯ НА УСЛОВИЯХ "AS IS".               }
{   АВТОР НЕ БЕРЕТ НА СЕБЯ И НЕ ПОДРАЗУМЕВАЕТ КАКИХ-ЛИБО ГАРАНТИЙНЫХ    }
{   ОБЯЗАТЕЛЬСТВ.                                                       }
{   АВТОР НЕ НЕСЕТ ОТВЕТСТВЕННОСТЬ ЗА ПОТЕРЮ ДАННЫХ, УЩЕРБ,             }
{   ПОТЕРЮ ПРИБЫЛИ ИЛИ ЛЮБЫЕ ДРУГИЕ ПОТЕРИ, ПРОИЗОШЕДШИЕ ВО ВРЕМЯ       }
{   ИСПОЛЬЗОВАНИЯ ИЛИ НЕПРАВИЛЬНОГО ИСПОЛЬЗОВАНИЯ ДАННОГО ПРОГРАММНОГО  }
{   ПРОДУКТА.                                                           }
{   ВЫ ПРИНИМАЕТЕ УСЛОВИЯ СОГЛАШЕНИЯ И ИСПОЛЬЗУЕТЕ TRySwapStream НА   }
{   СВОЙ СТРАХ И РИСК.                                                  }
{ Если вы не согласны с условиями настоящего лицензионного соглашения   }
{ вы не должны использовать TRySwapStream в Ваших проектах.           }
{***********************************************************************}

unit RySwapStream;

interface

uses Windows, SysUtils, RySharedMem, Classes;

type

{ TRyPageList }

  TRyPageList = class(TList)
  protected
    function  Get(Index: Integer): TRySharedMem;
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    property  Items[Index: Integer]: TRySharedMem read Get; default;
  end;

{ TRySwapStream }

  TRySwapStream = class(TStream)  { Для совместимости с TStream }
  private
    FSize     : Longint;          { Реальный размер записанных данных }
    FPosition : Longint;
    FPages    : TRyPageList;
  protected
    PageSize  : Longint;
    function  NewPage: TRySharedMem; virtual;
    procedure SetSize(NewSize: Longint); override;
  public
    constructor Create;
    destructor  Destroy; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    function  Read(var Buffer; Count: Longint): Longint; override;
    function  Write(const Buffer; Count: Longint): Longint; override;
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
  end;

implementation

uses RyActiveX;

const
  CPageSize = 1024000; { размер страницы }

{resourcestring
  CouldNotMapViewOfFile = 'Could not map view of file.';}

{ TRyPageList }

function TRyPageList.Get(Index: Integer): TRySharedMem;
begin
  Result := TRySharedMem(inherited Get(Index))
end;

procedure TRyPageList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then TRySharedMem(Ptr).Free;
  inherited;
end;

{ TRySwapStream }

{
  * Класс TRySwapStream можно рассматривать как альтернативу
    временным файлам (т.е. как замену TFileStream).
    Преимущество :
      а. Данные никто не сможет просмотреть.
      б. Страницы, зарезервированные под данные, автомотически освобождаются
         после уничтожения создавшего ее TRySwapStream'а.

  * Класс TRySwapStream можно рассматривать как альтернативу
    TMemoryStream.
    Преимущество :
      а. Не надо опасаться нехватки памяти при большом объеме записываемых данных.
         [случай когда физически нехватает места на диске здесь не рассматривается].

  Известные проблемы:
    На данный момент таких не выявлено.
    Но есть одно НО. Я не знаю как поведет себя TRySwapStream
    в результате нехватки места
      а. на диске
      б. в файле подкачки (т.е. в системе с ограниченным размером
                           файла подкачки).
}

constructor TRySwapStream.Create;
begin
  FPosition := 0;   { Позиция "курсора" }
  FSize     := 0;   { Размер данных }
  PageSize  := CPageSize;
  FPages    := TRyPageList.Create;
  {FPages.Add(NewPage);}
end;

destructor TRySwapStream.Destroy;
begin
  FPages.Free;
  inherited;
end;

function TRySwapStream.NewPage: TRySharedMem;
begin
  Result := TRySharedMem.Create(RyActiveX.GUIDToString(RyActiveX.GetGUID), 0, PageSize)
  {                                         |}
  {Я знаю что можно не именовать страницу __|}
  {но оказалось не всегда Win98 правильно создает новую}
  {неименнованную страницу. а другого способа получения}
  {уникальной строки я не знаю.                        }
  {если у кого-то будут идеи по этому поводу - милости просим.}
end;

function TRySwapStream.Seek(Offset: Longint; Origin: Word): Longint;
begin { Функция аналогичная TStream.Seek().
        Все пояснения по работе с ней см. в help'e. }
  case Origin of
    soFromBeginning : FPosition := Offset;
    soFromCurrent   : Inc(FPosition, Offset);
    soFromEnd       : FPosition := FSize - Offset;
  end;
  if FPosition > FSize then FPosition := FSize
  else if FPosition < 0 then FPosition := 0;
  Result := FPosition;
end;

procedure TRySwapStream.SetSize(NewSize: Longint);
var
  Sz: Longint;
begin { Функция аналогичная TStream.SetSize().
        Все пояснения по работе с ней см. в help'e. }
  inherited; {SetSize(NewSize);}

  Sz := Round( (NewSize / PageSize) + 0.5 ); {Кол-во страниц}

  {if NewSize > (PageSize * FPages.Count) then}
  if Sz > FPages.Count then { Если размер необходимый для записи
  данных больше размера выделенного под наш stream, то мы должны
  увеличить размер stream'a}
  begin { ...но FileMapping не поддерживает изменения размеров "страницы",
    что не очень удобно, поэтому приходится выкручиваться. }

    Sz := Sz{Round( (NewSize / PageSize) + 0.5 )} - FPages.Count;
    { думаем сколько нужно досоздать страниц под данные }

    while Sz > 0 do {создаем страницы}
    begin
      FPages.Add(NewPage);
      Dec(Sz);
    end;
  end else
  {if NewSize < (PageSize * FPages.Count) then}
  if Sz < FPages.Count then { Если размер необходимый для записи
  данных меньше размера выделенного под наш stream, то мы должны
  удалить лишние страницы}
  begin
    Sz := FPages.Count - Sz{Round( (NewSize / PageSize) + 0.5 )};
    { подсчитываем лишние страницы }

    while Sz > 0 do {удаляем страницы}
    begin
      FPages.Delete(FPages.Count - 1);
      Dec(Sz);
    end;
  end;

  FSize := NewSize;   { Запоминаем размер данных }

  if FPosition > FSize then FPosition := FSize;
end;

procedure TRySwapStream.LoadFromStream(Stream: TStream);
begin
  CopyFrom(Stream, 0);
end;

procedure TRySwapStream.SaveToStream(Stream: TStream);
begin
  Stream.CopyFrom(Self, 0);
end;

function TRySwapStream.Read(var Buffer; Count: Longint): Longint;
var
  FPageNo: Integer;
  FPos, BPos, ACount, FCount : Longint;
  Buf: Pointer;
begin
  Buf := @Buffer;
  ACount := 0;
  if Count > 0 then
  begin
    FCount := FSize - FPosition; {максимальное кол-во, которое можно прочитать}
    if FCount > 0 then
    begin
      if FCount > Count then FCount := Count; {если нам нужно прочитать меньше чем можем}
      ACount := FCount; {запоминаем сколько надо}
      FPageNo := FPosition div PageSize; {т.к. у нас многостраничный stream, то
      находим с какой страницы начать читать}
      BPos := 0;
      FPos := FPosition - (PageSize * FPageNo); {с какой позиции на странице читаем}
      while FCount > 0 do
      begin
        if FCount > (PageSize - FPos) then
           Count := PageSize - FPos else Count := FCount; {определяем
           сколько можно прочитать со страницы}
        Move(Pointer(Longint(FPages.Items[FPageNo].Memory) + FPos)^,
          Pointer(Longint(Buf) + BPos)^, Count);
        {считаваем инфо. в буффер}
        Inc(FPageNo); {переходим на следующую страницу}
        Dec(FCount, Count);
        Inc(BPos, Count);
        FPos := 0;
      end;
      Inc(FPosition, ACount);
    end
  end;

  Result := ACount;
end;

function TRySwapStream.Write(const Buffer; Count: Longint): Longint;
var
  FPageNo: Integer;
  FPos, BPos, ASize,
  ACount, FCount : Longint;
  Buf: Pointer;
begin { Функция аналогичная TStream.Write().
        Все пояснения по работе с ней см. в help'e. }
  Buf := @Buffer;
  if Count > 0 then
  begin
    ASize := FPosition + Count; {определяем сколько места нужно для данных}
    if FSize < ASize then Size := ASize; {если больше чем было, то увеличиваем размер стрима}

    FCount := Count; {запоминаем сколько надо записать}
    FPageNo := FPosition div PageSize; {определяем с какой страницы начинаем писать}
    BPos := 0;
    FPos := FPosition - (PageSize * FPageNo); {вычисляем позицию на странице}
    while FCount > 0 do {пока все не напишем ни куда не уходим}
    begin
      if FCount > (PageSize - FPos) then
         ACount := PageSize - FPos else ACount := FCount;
      Move(Pointer(Longint(Buf) + BPos)^,
        Pointer(Longint(FPages.Items[FPageNo].Memory) + FPos)^, ACount);
      {пишем сколько влезает до конца страницы}
      Inc(FPageNo); {переходим на следующую страницу}
      Dec(FCount, ACount); {уменьшаем кол-во незаписанных на кол-во записанных}
      Inc(BPos, ACount);
      FPos := 0;
    end;
    FPosition := ASize;
  end;

  Result := Count;
end;

end.
