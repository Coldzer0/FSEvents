(*
  * Project: FSEvents    ..
  * User   : Coldzer0    ..
  * Date   : 25/05/2017  ..
*)

program MacFSEvents;

{$mode Delphi}{$H+}
{$SMARTLINK ON}

{$IFDEF DARWIN}
  {$modeswitch objectivec1}  // this is must be ON .... fo Cocoa ..under Darwin <<<<<
  {.$modeswitch objectivec2}  // this is for the for..in loop .

  //{$linkframework ApplicationServices}
{$ENDIF}

uses
  cthreads,cmem,ctypes,sysutils,MacOSAll,CocoaAll;

{$MACRO ON}

const
  CRLF = #10#13;

function GetFileType( flag : integer) : string;
begin
  Result := '';
  if (flag and kFSEventStreamEventFlagItemIsFile) <> 0 then
   Result := 'IsFile';
  if (flag and kFSEventStreamEventFlagItemIsDir) <> 0 then
   Result := 'IsDir';
  if (flag and kFSEventStreamEventFlagItemIsSymlink) <> 0 then
   Result := 'IsSymlink';
  if (Result = '') then
    Result := 'Unknown FileType Flag';
end;

function GetFileChange( flag : integer) : string;
begin
  Result := '';
  if (flag and kFSEventStreamEventFlagItemInodeMetaMod) <> 0 then
   Result := 'Inode - MetaMod';
  if (flag and kFSEventStreamEventFlagItemFinderInfoMod) <> 0 then
   Result := 'Finder - InfoMod';
  if (flag and kFSEventStreamEventFlagItemChangeOwner) <> 0 then
   Result := 'ChangeOwner - access';
  if (flag and kFSEventStreamEventFlagItemXattrMod) <> 0 then
   Result := 'Xattrs - Mod';
  if (Result = '') then
    Result := 'Unknown FileChange Flag';
end;


function GetEventType( flag : integer ): string;
begin
    Result := '';
    if (flag and kFSEventStreamEventFlagItemRemoved) <> 0 then
    begin
         Result := 'Deleted';
         exit;
    end;

    if (flag and kFSEventStreamEventFlagItemRenamed) <> 0 then
    begin
         Result := 'moved - deleted or moved or renamed X_X';
         exit;
    end;

    if (flag and kFSEventStreamEventFlagItemCreated) <> 0 then
    begin
        Result := 'Created';
        exit;
    end;


    if (flag and kFSEventStreamEventFlagItemModified) <> 0 then
    begin
         Result := 'Modified';
         exit;
    end;

    if (flag and kFSEventStreamEventFlagRootChanged) <> 0 then
    begin
         Result := 'Root-Changed - the main monitored root dir';
         exit;
    end;
    if (flag and kFSEventStreamEventFlagOwnEvent) <> 0 then
     Result := 'OwnEvent - idk what is this :P';

     Result := 'Unknown EventType Flag';
end;

procedure EventsCallback(
  streamRef: ConstFSEventStreamRef;
  clientCallBackInfo: UnivPtr;
  numEvents: size_t;
  eventPaths: UnivPtr;
  {const} eventFlags: FSEventStreamEventFlagsPtr;
  {const} eventIds  : FSEventStreamEventIdPtr ); cdecl;
var
  i : integer;
  paths : PPCharArray;
  Flags : PIntegerArray;
begin

     writeln('====================================================================');
     writeln('numEvents   : ',numEvents);
     paths := PPCharArray(eventPaths);
     Flags := PIntegerArray(eventFlags);
     for i := 0 to numEvents -1 do
     begin
          writeln('Change in '+ PChar(paths[i]) +' - Flag : '+ IntToHex(Flags[i],8) + CRLF
                        +' FileEvent  : '+ GetEventType(Flags[i]) + CRLF
                        +' FileType   : '+ GetFileType(Flags[i]) + CRLF
                        +' FileChange : '+ GetFileChange(Flags[i]) + CRLF
                        +'--------------------------------');
     end;
end;

var
    pool: NSAutoreleasePool;
    stream : FSEventStreamRef;
    callbackinfo : FSEventStreamContext;
    pathsToWatch : CFArrayRef;
    mypath : CFStringRef;
    latency : CFAbsoluteTime;
begin
  pool:=NSAutoreleasePool.alloc.init;

  latency := 0.3; // more than enough .
  mypath := CFSTR(PChar(NSHomeDirectory.UTF8String + '/Desktop'));
  pathsToWatch := CFArrayCreate(nil,@mypath,1,nil);
  stream:= FSEventStreamCreate(nil,
                                   @EventsCallback,
                                   @callbackinfo,
                                   pathsToWatch,
                                   kFSEventStreamEventIdSinceNow,
                                   latency,
                                   kFSEventStreamCreateFlagFileEvents);

  FSEventStreamScheduleWithRunLoop(stream,CFRunLoopGetCurrent,kCFRunLoopDefaultMode);
  FSEventStreamStart(stream);

  CFRunLoopRun;

  pool.release;
end.

