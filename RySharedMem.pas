{***********************************************************************}
{                         ����� TRySharedMem.                           }
{                                                                       }
{ ������  : 1.0, 15 ������ 2002 �.                                      }
{ �����   : ������� ��������.                                           }
{ E-mail  : skitl@mail.ru                                               }
{-----------------------------------------------------------------------}
{ ��������:                                                             }
{   * ��������� � �������� ������ � ������ ��������.                    }
{-----------------------------------------------------------------------}
{    ���������� ��� ����������� ������ http://www.delphikingdom.com     }
{-----------------------------------------------------------------------}
{ �������� �� Delphi5. ������������� �� Win98, WinXP.                   }
{ � ������ ����������� ������ ��� ��������������� � ������� ��������    }
{ Delphi � Windows, ������� �������� ������.                            }
{-----------------------------------------------------------------------}
{ ������������ ����������:                                              }
{ * TRySharedMem ���������������� �� �������� "AS IS".                  }
{   ����� �� ����� �� ���� � �� ������������� �����-���� �����������    }
{   ������������.                                                       }
{   ����� �� ����� ��������������� �� ������ ������, �����,             }
{   ������ ������� ��� ����� ������ ������, ������������ �� �����       }
{   ������������� ��� ������������� ������������� ������� ������������  }
{   ��������.                                                           }
{   �� ���������� ������� ���������� � ����������� TRySharedMem ��      }
{   ���� ����� � ����.                                                  }
{ ���� �� �� �������� � ��������� ���������� ������������� ����������   }
{ �� �� ������ ������������ TRySharedMem � ����� ��������.              }
{***********************************************************************}

unit RySharedMem;

interface

uses Windows;

type

{ TRySharedMem }

{ This class simplifies the process of creating a region of shared memory.
  In Win32, this is accomplished by using the CreateFileMapping and
  MapViewOfFile functions. }
{ ���� ����� �������� �������� shared ������� � ������.
  � Win32, ��� �������� ������� ��������� ������� CreateFileMapping and
  MapViewOfFile }

  TRySharedMem = class(TObject)
  private
    FActive: Boolean;
    FName   : String;
    FSize   : Longint;
    FMemory : Pointer;
    FPosition: Longint; { ������� ������� "�������" �� "��������" }
    SHandle : THandle;
  public
    constructor Create(const Name: String; Handle : THandle; Size: Longint);
    destructor  Destroy; override;
  public {��� ������� ���������� �������(������/������) �� ��������� ������.
    �������� �� ���� �� �������� ��� � � TStream, �� ������� ������/������ ����������,
    �� ������ ����������� ������ ��������, ����� ��������������� ��� �������.
    ����� ������� ������� - ������� ��� ������� � ����.}
    function  Read(var Buffer; Count: Longint): Longint;
    function  Write(const Buffer; Count: Longint): Longint;
  public
    PAGE_ALREADY_EXISTS: Boolean;
    property  Active  : Boolean read FActive; {����� �������� TRySharedMem
    � ��������� �������� �������� ������ Active ���������� True,
    � ������ ������-���� ���� Active = False - �.�. �������� �� �������,
    ������������� ������/������ �� ��������.}
    property  Position: Longint read FPosition write FPosition;
    property  Name    : String  read FName; {����� �������������� property}
    property  Size    : Longint read FSize; {��� � ������ ������ ������   }
    property  Memory  : Pointer read FMemory {���� ������ �������� � ����������,
    �� ��� ��� ������� � �������� ������, � ��������� ������ ��������������
    ��������� Read()/Write()};
  end;

{-�������������� ��������� � �������-------------------------------------------}
const
  SwapHandle = $FFFFFFFF; { Handle ����� �������� }

procedure ApplicationInit(const AppName: String; const Handle: THandle);
{ ���� �� ������ ����� ������ ��������������� ���� ������������� � ������,
  �� �������� ��� ���������, ������� � �������� ��������� ���������� ���
  ������� ���. ��������� �� ��������� ������������� ����� ��������, �
  ������ ������������ ���� �����. ��������� �������������� ��������
  ����� �������� �� ������������� ��� ��������� �����. }

function  IsApplicationRunning(const AppName: String; var Handle: THandle): Boolean;
{ ������� ���������� ��������� �������� �� ������������� ���������
  ����� ��������� �, ��� ������������� ����������, Handle ����������
  �����. ������� �� ������������� ��������� ����� - AppName.}

procedure RestoreApplication(const Handle: THandle);
{ �������������� �� ������ ������. ��������� � ������ ��������� ������������� �
  ����� ���������� �� �� ������ ����. �� � �������� ��������� ������ ����
  ������� Application.Handle, � �� MainForm.Handle. }

function  CheckPreviousAppInstance(const AppName: String): Boolean;
{ ������� ��������� ������������� ��������� ����� ���������, �������������� �� �
  ���������� ��������� ��������. ������� �������������� �������� ��
  ����������� �������. }

{------------------------------------------------------------------------------}

implementation

{resourceString
  CouldNotMapViewOfFile = 'Could not map view of file.';}

{ TRySharedMem }

constructor TRySharedMem.Create(const Name: String; Handle : THandle; Size: Longint);
begin
  FName := Name;
  FSize := Size;  { ������ �������� }
  FPosition := 0; { ������� ������� "�������" �� "��������" }
  FActive := True;
  if Handle = 0 then Handle := SwapHandle;
  { � �������� ��������� Handle �� ������ ��������
      ���� Handle �����, � ����� ������� ����� �������� = Size �����
           ����� ����� ��������� (Memory) �� ��� �������,
      ���� 0 ��� SwapHandle, � ����� � ����� �������� ����� ������� ��������
           � ������� ����� �������� - ������� ��������� ����������,
           ������������ ����������� ����� ������������, � �.�., }

  { ������� ���������� ������� ����������� ������. //��� ������������ ����� �� �����
    ����� ������� - ������� �������� ��� ������.   //���������, � ����� � �����
                                                   //���� ����������� ����� ������
                                                   //�������������� �������.
    ��� ����������� �� CreateFileMapping � Help'e. }
  SHandle := CreateFileMapping(Handle, nil, PAGE_READWRITE, 0, Size, PChar(Name));
  { ������� "��������"___|      |                                 |   |}
  { Handle ����� ��� Swap'a_____|                                 |   |}
  { ������ ������ "��������"[Sz]. �� ����� ���� = ���� ___________|   |}
  { ��� "��������". __________________________________________________|
      ���� �� �������������� ������ �������� � ������� ������������, ��
      ������� ���������� ��� ��� ��������. }
  if SHandle = 0 then FActive := False; { ������ -
     ��������� ������� ������ �����������[�.�. "��������" �� ������� � ��������� �� ��� = 0].
     ��� ����� ����:
        ���� �� ���-���� �������� � ������������ -
            a. ��-�� ������ � ����������, ������������ ������� CreateFileMapping
            �. ���� Sz <= 0
        ���� �� ������ �� �������� -
            �. �� ����� ������ ��������� ����� �������������� �������� � OS ���
               ������������ ������ � FileMapping'�� � ����� ��� ����� ���������.
               �������� ������������ ������� }

  { We still need to map a pointer to the handle of the shared memory region }
  { �������� ��������� �� ���������� ������ }
  if FActive then
  begin
    PAGE_ALREADY_EXISTS := Windows.GetLastError = ERROR_ALREADY_EXISTS;
    FMemory := MapViewOfFile(SHandle, FILE_MAP_WRITE, 0, 0, Size);
  end;
  if FMemory = nil then FActive := False;{ ������ �������
     ����� ������������ � ������� nil, �� � ����� �������� �� ��������.
     ����������� ���� �� ���������� �������� �� ��������� ������ � ����
     �������� ���������� ��������� ��� ������� MapViewOfFile() }
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

{-�������������� ��������� � �������-------------------------------------------}

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

