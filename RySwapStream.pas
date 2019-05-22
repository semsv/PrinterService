{***********************************************************************}
{                         ����� TRySwapSream.                         }
{                                                                       }
{ ������  : 2.0, 15 ������ 2002 �.                                      }
{ �����   : ������� ��������.                                           }
{ E-mail  : skitl@mail.ru                                               }
{-----------------------------------------------------------------------}
{ ��������:                                                             }
{   * ��������� � �������� ������ � ������ ��������.                    }
{   * ����� ��������������� ��� ������������ TFileStream, TMemoryStream.}
{-----------------------------------------------------------------------}
{    ���������� ��� ����������� ������ http://www.delphikingdom.com     }
{-----------------------------------------------------------------------}
{ �������� �� Delphi5. ������������� �� Win98, WinXP.                   }
{ � ������ ����������� ������ ��� ��������������� � ������� ��������    }
{ Delphi � Windows, ������� �������� ������.                            }
{-----------------------------------------------------------------------}
{ ������������ ����������:                                              }
{ * TRySwapStream ���������������� �� �������� "AS IS".               }
{   ����� �� ����� �� ���� � �� ������������� �����-���� �����������    }
{   ������������.                                                       }
{   ����� �� ����� ��������������� �� ������ ������, �����,             }
{   ������ ������� ��� ����� ������ ������, ������������ �� �����       }
{   ������������� ��� ������������� ������������� ������� ������������  }
{   ��������.                                                           }
{   �� ���������� ������� ���������� � ����������� TRySwapStream ��   }
{   ���� ����� � ����.                                                  }
{ ���� �� �� �������� � ��������� ���������� ������������� ����������   }
{ �� �� ������ ������������ TRySwapStream � ����� ��������.           }
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

  TRySwapStream = class(TStream)  { ��� ������������� � TStream }
  private
    FSize     : Longint;          { �������� ������ ���������� ������ }
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
  CPageSize = 1024000; { ������ �������� }

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
  * ����� TRySwapStream ����� ������������� ��� ������������
    ��������� ������ (�.�. ��� ������ TFileStream).
    ������������ :
      �. ������ ����� �� ������ �����������.
      �. ��������, ����������������� ��� ������, ������������� �������������
         ����� ����������� ���������� �� TRySwapStream'�.

  * ����� TRySwapStream ����� ������������� ��� ������������
    TMemoryStream.
    ������������ :
      �. �� ���� ��������� �������� ������ ��� ������� ������ ������������ ������.
         [������ ����� ��������� ��������� ����� �� ����� ����� �� ���������������].

  ��������� ��������:
    �� ������ ������ ����� �� ��������.
    �� ���� ���� ��. � �� ���� ��� ������� ���� TRySwapStream
    � ���������� �������� �����
      �. �� �����
      �. � ����� �������� (�.�. � ������� � ������������ ��������
                           ����� ��������).
}

constructor TRySwapStream.Create;
begin
  FPosition := 0;   { ������� "�������" }
  FSize     := 0;   { ������ ������ }
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
  {� ���� ��� ����� �� ��������� �������� __|}
  {�� ��������� �� ������ Win98 ��������� ������� �����}
  {�������������� ��������. � ������� ������� ���������}
  {���������� ������ � �� ����.                        }
  {���� � ����-�� ����� ���� �� ����� ������ - ������� ������.}
end;

function TRySwapStream.Seek(Offset: Longint; Origin: Word): Longint;
begin { ������� ����������� TStream.Seek().
        ��� ��������� �� ������ � ��� ��. � help'e. }
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
begin { ������� ����������� TStream.SetSize().
        ��� ��������� �� ������ � ��� ��. � help'e. }
  inherited; {SetSize(NewSize);}

  Sz := Round( (NewSize / PageSize) + 0.5 ); {���-�� �������}

  {if NewSize > (PageSize * FPages.Count) then}
  if Sz > FPages.Count then { ���� ������ ����������� ��� ������
  ������ ������ ������� ����������� ��� ��� stream, �� �� ������
  ��������� ������ stream'a}
  begin { ...�� FileMapping �� ������������ ��������� �������� "��������",
    ��� �� ����� ������, ������� ���������� �������������. }

    Sz := Sz{Round( (NewSize / PageSize) + 0.5 )} - FPages.Count;
    { ������ ������� ����� ��������� ������� ��� ������ }

    while Sz > 0 do {������� ��������}
    begin
      FPages.Add(NewPage);
      Dec(Sz);
    end;
  end else
  {if NewSize < (PageSize * FPages.Count) then}
  if Sz < FPages.Count then { ���� ������ ����������� ��� ������
  ������ ������ ������� ����������� ��� ��� stream, �� �� ������
  ������� ������ ��������}
  begin
    Sz := FPages.Count - Sz{Round( (NewSize / PageSize) + 0.5 )};
    { ������������ ������ �������� }

    while Sz > 0 do {������� ��������}
    begin
      FPages.Delete(FPages.Count - 1);
      Dec(Sz);
    end;
  end;

  FSize := NewSize;   { ���������� ������ ������ }

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
    FCount := FSize - FPosition; {������������ ���-��, ������� ����� ���������}
    if FCount > 0 then
    begin
      if FCount > Count then FCount := Count; {���� ��� ����� ��������� ������ ��� �����}
      ACount := FCount; {���������� ������� ����}
      FPageNo := FPosition div PageSize; {�.�. � ��� ��������������� stream, ��
      ������� � ����� �������� ������ ������}
      BPos := 0;
      FPos := FPosition - (PageSize * FPageNo); {� ����� ������� �� �������� ������}
      while FCount > 0 do
      begin
        if FCount > (PageSize - FPos) then
           Count := PageSize - FPos else Count := FCount; {����������
           ������� ����� ��������� �� ��������}
        Move(Pointer(Longint(FPages.Items[FPageNo].Memory) + FPos)^,
          Pointer(Longint(Buf) + BPos)^, Count);
        {��������� ����. � ������}
        Inc(FPageNo); {��������� �� ��������� ��������}
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
begin { ������� ����������� TStream.Write().
        ��� ��������� �� ������ � ��� ��. � help'e. }
  Buf := @Buffer;
  if Count > 0 then
  begin
    ASize := FPosition + Count; {���������� ������� ����� ����� ��� ������}
    if FSize < ASize then Size := ASize; {���� ������ ��� ����, �� ����������� ������ ������}

    FCount := Count; {���������� ������� ���� ��������}
    FPageNo := FPosition div PageSize; {���������� � ����� �������� �������� ������}
    BPos := 0;
    FPos := FPosition - (PageSize * FPageNo); {��������� ������� �� ��������}
    while FCount > 0 do {���� ��� �� ������� �� ���� �� ������}
    begin
      if FCount > (PageSize - FPos) then
         ACount := PageSize - FPos else ACount := FCount;
      Move(Pointer(Longint(Buf) + BPos)^,
        Pointer(Longint(FPages.Items[FPageNo].Memory) + FPos)^, ACount);
      {����� ������� ������� �� ����� ��������}
      Inc(FPageNo); {��������� �� ��������� ��������}
      Dec(FCount, ACount); {��������� ���-�� ������������ �� ���-�� ����������}
      Inc(BPos, ACount);
      FPos := 0;
    end;
    FPosition := ASize;
  end;

  Result := Count;
end;

end.
