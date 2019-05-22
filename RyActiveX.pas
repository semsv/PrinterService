unit RyActiveX;

interface

uses Windows, ActiveX;

function StringToGUID(const S: String): TGUID;
function GUIDToString(const ClassID: TGUID): String;
function GetGUID : TGUID;

const
  GuidSize = SizeOf(TGUID);
  NullGuid: TGuid = '{00000000-0000-0000-0000-000000000000}';

implementation

{ Convert a string to a GUID }

function StringToGUID(const S: String): TGUID;
begin
  CLSIDFromString(PWideChar(WideString(S)), Result)
end;

{ Convert a GUID to a string }

function GUIDToString(const ClassID: TGUID): String;
var
  P: PWideChar;
begin
  StringFromCLSID(ClassID, P);
  Result := P;
  CoTaskMemFree(P);
end;

function GetGUID : TGUID;
begin
  CoCreateGuid(Result);
end;

end.
