program memguard;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, sysutils, FileUtil, dregexpr, BaseUnix, unix
  { you can add units after this };

{$R *.res}

type TProcessInfo = record
  name: string;
  pid: integer;
  uid: integer;
  rss: int64;
end;

{


[RSDZTW]

ppid %d

pgrp %d

session %d

tty_nr %d

tpgid %d

    flags %u (%lu before Linux 2.6.22)

minflt %lu

cminflt %lu

majflt %lu

cmajflt %lu

utime %lu

stime %lu

cutime %ld

cstime %ld

priority %ld

nice %ld

num_threads %ld

itrealvalue %ld

starttime %llu (was %lu before Linux 2.6)

vsize %lu

rss %ld
}

var processInfoRegex: TRegExpr = nil;
function getProcessInformation(const pid: integer; out p: TProcessInfo): boolean;
const PAGE_SIZE = 4096; //bytes
var spid, state: string;
    f: TextFile;
    dirstat: stat;
begin
  spid:=inttostr(pid);
  FpStat('/proc/'+spid+'/stat', dirstat);
  p.uid := dirstat.st_uid;
  if p.uid = 0 then exit(false);

  if processInfoRegex = nil then
    processInfoRegex := TRegExpr.create('^([0-9]+) [(](.*)[)] [RSDZTW] ([-0-9]+ ){20}([0-9]+).*');

  try
    AssignFile(f, '/proc/'+spid+'/stat');
    Reset(f);
  except
    result:=false;
    exit;
  end;
  readln(f,state);
  processInfoRegex.Exec(state);
  CloseFile(f);

  if processInfoRegex.Match[1] <> spid then exit(false);

  p.name := processInfoRegex.match[2];
  p.pid := pid;
  p.rss:=PAGE_SIZE * StrToInt64Def(processInfoRegex.Match[4],0);

  result:=true;
end;

var lastUsage: array[0..65535] of int64;
    whiteList: TStringList;
procedure check;
const MiBi: int64 = 1024*1024;
var sl:TStringList;
 i: Integer;
 proc: TProcessInfo;
 pid: Integer;
 wl: Integer;
begin
  sl:=FindAllDirectories('/proc',false);
  for i:=0 to sl.Count-1 do begin
    pid := StrToIntDef(copy(sl[i],7,100), -1);
    if pid = -1 then continue;
    if not getProcessInformation(pid, proc) then continue;
    if proc.uid = 0 then continue;
    if proc.rss < 50*MiBi then continue;


    if proc.rss > 255*MiBi then begin
      wl := whiteList.IndexOf(proc.name);
      if wl >= 0 then
        if proc.rss < int64(PtrInt(whiteList.Objects[wl])) * MiBi then continue;

      writeln(inttostr(proc.pid)+': '+proc.name+' '+inttostr(proc.rss div MiBi));//, '         STOPPED  (use kill -CONT to allow)');
      fpSystem('kill -STOP '+IntToStr(pid));
    end;
  end;
end;

procedure allow(prog: string; maxMiBi: PtrInt);
begin
  whiteList.AddObject(prog, tobject(maxMiBi));
end;
begin
  fpNice(-10);
  whiteList := TStringList.Create;
  allow('firefox-bin', 4000);
  allow('qtcreator', 4000);
  allow('cc1plus', 1500);

  while true do begin
    check;
    Sleep(2000);
  end;
end.

