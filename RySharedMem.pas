{***********************************************************************}
{                         Класс TRySharedMem.                           }
{                                                                       }
{ Версия  : 1.0, 15 апреля 2002 г.                                      }
{ Автор   : Алексей Румянцев.                                           }
{ E-mail  : skitl@mail.ru                                               }
{-----------------------------------------------------------------------}
{ Описание:                                                             }
{   * Реализует и упрощает работу с файлом подкачки.                    }
{-----------------------------------------------------------------------}
{    Специально для Королевства Дельфи http://www.delphikingdom.com     }
{-----------------------------------------------------------------------}
{ Написано на Delphi5. Тестировалось на Win98, WinXP.                   }
{ В случае обнаружения ошибки или несовместимости с другими версиями    }
{ Delphi и Windows, просьба сообщить автору.                            }
{-----------------------------------------------------------------------}
{ Лицензионное соглашение:                                              }
{ * TRySharedMem РАСПРОСТРАНЯЕТСЯ НА УСЛОВИЯХ "AS IS".                  }
{   АВТОР НЕ БЕРЕТ НА СЕБЯ И НЕ ПОДРАЗУМЕВАЕТ КАКИХ-ЛИБО ГАРАНТИЙНЫХ    }
{   ОБЯЗАТЕЛЬСТВ.                                                       }
{   АВТОР НЕ НЕСЕТ ОТВЕТСТВЕННОСТЬ ЗА ПОТЕРЮ ДАННЫХ, УЩЕРБ,             }
{   ПОТЕРЮ ПРИБЫЛИ ИЛИ ЛЮБЫЕ ДРУГИЕ ПОТЕРИ, ПРОИЗОШЕДШИЕ ВО ВРЕМЯ       }
{   ИСПОЛЬЗОВАНИЯ ИЛИ НЕПРАВИЛЬНОГО ИСПОЛЬЗОВАНИЯ ДАННОГО ПРОГРАММНОГО  }
{   ПРОДУКТА.                                                           }
{   ВЫ ПРИНИМАЕТЕ УСЛОВИЯ СОГЛАШЕНИЯ И ИСПОЛЬЗУЕТЕ TRySharedMem НА      }
{   СВОЙ СТРАХ И РИСК.                                                  }
{ Если вы не согласны с условиями настоящего лицензионного соглашения   }
{ вы не должны использовать TRySharedMem в Ваших проектах.              }
{***********************************************************************}

unit RySharedMem;

interface

uses Windows;

type

{ TRySharedMem }

{ This class simplifies the process of creating a region of shared memory.
  In Win32, this is accomplished by using the CreateFileMapping and
  MapViewOfFile functions. }
{ Этот класс упрощает создание shared региона в памяти.
  В Win32, это возмажно сделать используя функции CreateFileMapping and
  MapViewOfFile }

  TRySharedMem = class(TObject)
  private
    FActive: Boolean;
    FName   : String;
    FSize   : Longint;
    FMemory : Pointer;
    FPosition: Longint; { Текущая позиция "курсора" на "странице" }
    SHandle : THandle;
  public
    constructor Create(const Name: String; Handle : THandle; Size: Longint);
    destructor  Destroy; override;
  public {две функции упрощающие общение(чтение/запись) со страницей памяти.
    работают по тому же принципу что и в TStream, но попытка чтения/записи информации,
    по объему превышающей размер страницы, будет проигнорирована или урезана.
    Здесь принцып простой - сколько дал столько и взял.}
    function  Read(var Buffer; Count: Longint): Longint;
    function  Write(const Buffer; Count: Longint): Longint;
  public
    PAGE_ALREADY_EXISTS: Boolean;
    property  Active  : Boolean read FActive; {после создания TRySharedMem
    и успешного создания страницы памяти Active становится True,
    В случае какого-либо сбоя Active = False - т.е. страница не создана,
    следовательно запись/чтение не возможны.}
    property  Position: Longint read FPosition write FPosition;
    property  Name    : String  read FName; {чисто информационные property}
    property  Size    : Longint read FSize; {имя и размер менять нельзя   }
    property  Memory  : Pointer read FMemory {Если умеете работать с указателем,
    то вот Вам ниточка к странице памяти, в противном случае воспользуйтесь
    функциями Read()/Write()};
  end;

{-Дополнительные процедуры и функции-------------------------------------------}
const
  SwapHandle = $FFFFFFFF; { Handle файла подкачки }

procedure ApplicationInit(const AppName: String; const Handle: THandle);
{ Если Вы хотите чтобы проект зарегестрировал свое существование в памяти,
  то вызовите эту процедуру, передав в качестве параметра уникальное для
  проекта имя. Процедура не проверяет существование копий программ, а
  только регистрирует свою копию. Процедуру предполагается вызывать
  после проверки на существование уже запущеной копии. }

function  IsApplicationRunning(const AppName: String; var Handle: THandle): Boolean;
{ Функция возвращает результат проверки на существование запущеных
  копий программы и, при положительном результате, Handle предыдущей
  копии. Следите за правильностью написания имени - AppName.}

procedure RestoreApplication(const Handle: THandle);
{ Востанавливает на экране проект. Свернутую в значек программу разворачивает и
  затем выставляет ее на первый план. Но в качестве параметра должен быть
  передан Application.Handle, а не MainForm.Handle. }

function  CheckPreviousAppInstance(const AppName: String): Boolean;
{ Функция проверяет существование запущеной копии программы, востанавливает ее и
  возвращает результат проверки. Функцию предполагается вызывать до
  регистрации проекта. }

{------------------------------------------------------------------------------}

implementation

{resourceString
  CouldNotMapViewOfFile = 'Could not map view of file.';}

{ TRySharedMem }

constructor TRySharedMem.Create(const Name: String; Handle : THandle; Size: Longint);
begin
  FName := Name;
  FSize := Size;  { Размер страницы }
  FPosition := 0; { Текущая позиция "курсора" на "странице" }
  FActive := True;
  if Handle = 0 then Handle := SwapHandle;
  { В качестве параметра Handle Вы можете передать
      либо Handle файла, и тогда область файла размером = Size будет
           видна через указатель (Memory) на эту область,
      либо 0 или SwapHandle, и тогда в файле подкачки будет создата страница
           с которой можно работать - хранить временную информацию,
           обмениваться информацией между приложениями, и т.д., }

  { Создаем дескриптор объекта отображения данных. //эта формулеровка взята из книги
    Проще сказать - создаем страницу под данные.   //разрешите, я здесь и далее
                                                   //буду употреблять более протые
                                                   //информационные вставки.
    Все подробности по CreateFileMapping в Help'e. }
  SHandle := CreateFileMapping(Handle, nil, PAGE_READWRITE, 0, Size, PChar(Name));
  { Создаем "страницу"___|      |                                 |   |}
  { Handle файла или Swap'a_____|                                 |   |}
  { Задаем размер "страницы"[Sz]. Не может быть = нулю ___________|   |}
  { Имя "страницы". __________________________________________________|
      Если не предполагается делить страницу с другими приложениями, то
      давайте уникальное имя для страницы. }
  if SHandle = 0 then FActive := False; { ошибка -
     неудалось создать объект отображения[т.е. "страница" не создана и указатель на нее = 0].
     Это может быть:
        Если Вы что-либо изменяли в конструкторе -
            a. Из-за ошибки в параметрах, передоваемых функции CreateFileMapping
            б. Если Sz <= 0
        Если Вы ничего не изменяли -
            а. То такое бывает случается после исключительных ситуаций в OS или
               некорректной работы с FileMapping'ом в Вашей или чужой программе.
               Помогает перезагрузка виндуса }

  { We still need to map a pointer to the handle of the shared memory region }
  { Получаем указатель на выделенный регион }
  if FActive then
  begin
    PAGE_ALREADY_EXISTS := Windows.GetLastError = ERROR_ALREADY_EXISTS;
    FMemory := MapViewOfFile(SHandle, FILE_MAP_WRITE, 0, 0, Size);
  end;
  if FMemory = nil then FActive := False;{ Виндус наверно
     может взбрыкнуться и вернуть nil, но я таких ситуаций не встречал.
     естественно если на предыдущих дейсвиях не возникало ошибок и если
     переданы корректные параметры для функции MapViewOfFile() }
end;

destructor TRySharedMem.Destroy;
begin
  if FActive then
  begin
    UnmapViewOfFile(FMemory);
    CloseHandle(SHandle);
  end;
  inherited;
end;

function TRySharedMem.Read(var Buffer; Count: Longint): Longint;
var
  ACount: Longint;
begin
  ACount := 0;
  if FActive and (Count > 0) then
  begin
    ACount := FSize - FPosition;
    if (ACount > 0) and (ACount >= Count) then
    begin
      if ACount > Count then ACount := Count;
      Move((PChar(FMemory) + FPosition)^, Buffer, ACount);
      Inc(FPosition, ACount);
    end else
      ACount := 0
  end;
  Result := ACount;
end;

function TRySharedMem.Write(const Buffer; Count: Longint): Longint;
var
  I : Longint;
  ACount: Longint;
begin
  ACount := 0;
  if FActive and (Count > 0) then
  begin
    I := FPosition + Count;
    if FSize < I then ACount := 0
    else begin
      System.Move(Buffer, (PChar(FMemory) + FPosition)^, Count);
      FPosition := I;
      ACount := Count;
    end
  end;
  Result := ACount;
end;

{-Дополнительные процедуры и функции-------------------------------------------}

var
  SharedApp: TRySharedMem = nil;

procedure ApplicationInit(const AppName: String; const Handle: THandle);
begin
  SharedApp := TRySharedMem.Create(AppName, 0, SizeOf(THandle));
  if SharedApp.Active then SharedApp.Write(Handle, SizeOf(THandle));
end;

procedure ApplicationFin;
begin
  SharedApp.Free
end;

function IsApplicationRunning(const AppName: String; var Handle: THandle): Boolean;
begin
  with TRySharedMem.Create(AppName, 0, SizeOf(THandle)) do
  try
    if Active then
    begin
      Read(Handle, SizeOf(THandle));
      Result := PAGE_ALREADY_EXISTS;// or (Handle <> 0);
    end else
      Result := False
  finally
    Free
  end
end;

procedure RestoreApplication(const Handle: THandle);
begin
  if not IsWindowVisible(Handle) then Exit;
  if IsIconic(Handle) then ShowWindow(Handle, SW_RESTORE);
  SetForegroundWindow(Handle);
  {Halt(0);}
end;

function CheckPreviousAppInstance(const AppName: String): Boolean;
var
  Handle: THandle;
begin
  Result := IsApplicationRunning(AppName, Handle);
  if Result then
    RestoreApplication(Handle)
end;

{------------------------------------------------------------------------------}

initialization
finalization
  {-----------------------------------------}
  if Assigned(SharedApp) then ApplicationFin;
  {-----------------------------------------}

end.

