(******************************************************************************)
(*                                                                            *)
(*  Kandiral Ruslan                                                           *)
(*  https://kandiral.ru                                                       *)
(*                                                                            *)
(*  KRSpeedInfo                                                               *)
(*  Ver.: 14.07.2020                                                          *)
(*                                                                            *)
(*                                                                            *)
(******************************************************************************)
unit KRSpeedInfo;

interface

uses
  {$IF CompilerVersion >= 23}
    System.Classes, System.SysUtils, Vcl.StdCtrls, Vcl.Forms, Winapi.MMSystem,
  {$ELSE}
    Classes, SysUtils, StdCtrls, Forms, MMSystem,
  {$IFEND}
  KRTimer, KRNormalArray, Funcs;

type
  IKRSpeedInfo = interface
    ['{5ACA1384-A962-47A6-8C67-33DB5FF80A23}']
    function GetCounter: Cardinal; stdcall;
  end;

  TKRSpeedStep = (ssSecond, ssMinute, ssHour);

  TKRSpeedInfo = class(TCustomLabel, IKRTimer)
  private
    FComponent: IKRSpeedInfo;
    FTimer: TKRTimer;
    FOldCounter: Cardinal;
    FOldDT: Cardinal;
    FFormat: String;
    FSpeedUnit: String;
    FNrmArray: TKRNormalArray255;
    FSpeedStep: TKRSpeedStep;
    FAverageSpeed: byte;
    procedure SetComponent(const Value: IKRSpeedInfo);
    procedure SetTimer(const Value: TKRTimer);
    procedure SetAverageSpeed(const Value: byte);
    procedure SetSpeedStep(const Value: TKRSpeedStep);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoTimer; stdcall;
  public
    constructor Create(AOwner: TComponent);override;
    destructor Destroy;override;
  published
    property Component: IKRSpeedInfo read FComponent write SetComponent;
    property Timer: TKRTimer read FTimer write SetTimer;
    property Format: String read FFormat write FFormat;
    property SpeedUnit: String read FSpeedUnit write FSpeedUnit;
    property SpeedStep: TKRSpeedStep read FSpeedStep write SetSpeedStep default ssSecond;
    property AverageSpeed: byte read FAverageSpeed write SetAverageSpeed default 10;
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Caption;
    property Color nodefault;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property EllipsisPosition;
    property Enabled;
    property FocusControl;
    property Font;
    property GlowSize; // Windows Vista only
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Touch;
    property Transparent;
    property Layout;
    property Visible;
    property WordWrap;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

{ TKRSpeedInfo }

constructor TKRSpeedInfo.Create(AOwner: TComponent);
begin
  inherited;
  FNrmArray:=TKRNormalArray255.Create;
  FNrmArray.Len:=10;
  FAverageSpeed:=10;
  FFormat:='0.00';
  FSpeedStep:=ssSecond;
end;

destructor TKRSpeedInfo.Destroy;
begin
  if(Assigned(FTimer))then begin
    while FTimer.Working do Application.ProcessMessages;
    FTimer.DelMon(Self);
  end;
  FNrmArray.Free;
  inherited;
end;

procedure TKRSpeedInfo.DoTimer;
var
  _cntr,_rz,k: Cardinal;
  _spd: Extended;
  s: String;
begin
  _spd:=0;
  if Assigned(FComponent) then begin
    _cntr:=FComponent.GetCounter;
    if _cntr<FOldCounter then _rz:=$FFFFFFFF-FOldCounter+_cntr else _rz:=_cntr-FOldCounter;
    k:=1;
    case FSpeedStep of
      ssSecond: k:=1000;
      ssMinute: k:=60000;
      ssHour: k:=3600000;
    end;
    _spd:=_rz/(funcs.ElapsedTime(FOldDt)/k);
    FOldCounter:=_cntr;
    FOldDT:={$IF CompilerVersion >= 23}Winapi.{$IFEND}MMSystem.timeGetTime;
  end;
  if FFormat<>'' then s:=FormatFloat(FFormat,_spd) else s:=FloatToStr(_spd);
  if FAverageSpeed>0 then begin
    FNrmArray.Add(_spd);
    s:=s+'(';
    if FFormat<>'' then s:=s+FormatFloat(FFormat,FNrmArray.Average)+')' else s:=s+FloatToStr(FNrmArray.Average)+')';
  end;
  if FSpeedUnit<>'' then s:=s+' '+FSpeedUnit;
  Caption:=s;
end;

procedure TKRSpeedInfo.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if(Operation = opRemove)then
    if (AComponent = TComponent(FComponent))then FComponent:= nil else
    if (AComponent = FTimer)then begin
      FTimer:=nil;
    end;

end;

procedure TKRSpeedInfo.SetAverageSpeed(const Value: byte);
begin
  if Value<2 then FAverageSpeed:=0 else begin
    FAverageSpeed:=Value;
    FNrmArray.Len:=Value;
  end;
end;

procedure TKRSpeedInfo.SetComponent(const Value: IKRSpeedInfo);
begin
  if FComponent<>Value then begin
    if Assigned(Value) then begin
        FComponent:=Value;
        TComponent(FComponent).FreeNotification(Self);
        FOldCounter:=FComponent.GetCounter;
        FOldDT:={$IF CompilerVersion >= 23}Winapi.{$IFEND}MMSystem.timeGetTime;
        FNrmArray.Clear;
    end else FComponent:=nil;
  end;

end;

procedure TKRSpeedInfo.SetSpeedStep(const Value: TKRSpeedStep);
begin
  FSpeedStep := Value;
  FNrmArray.Clear;
end;

procedure TKRSpeedInfo.SetTimer(const Value: TKRTimer);
begin
  if FTimer<>Value then begin
    if(Assigned(FTimer))then begin
      while FTimer.Working do Application.ProcessMessages;
      FTimer.DelMon(Self);
    end;
    FTimer := Value;
    if(Assigned(FTimer))then begin
      FTimer.FreeNotification(Self);
      while FTimer.Working do Application.ProcessMessages;
      FTimer.AddMon(Self);
    end;
  end;
end;

end.
