--!strict
-- A single server's two-player queue. No simulated opponent or cross-server matchmaking.
local Queue={}
export type Service={Join: (number) -> (boolean,string),Cancel: (number) -> boolean,Remove: (number) -> boolean,Finish: () -> (),Snapshot: () -> {waiting: {number},active: {number},starting: boolean}}
function Queue.new(ready: (number) -> boolean,startPair: (number,number) -> boolean): Service
 local waiting: {number}={};local active: {number}={};local starting=false
 local api={} :: Service
 function api.Cancel(id: number): boolean local index=table.find(waiting,id);if not index then return false end;table.remove(waiting,index);return true end
 function api.Join(id: number): (boolean,string)
  if starting or #active>0 then return false,"Busy" end
  if table.find(waiting,id) then return false,"AlreadyQueued" end
  if not ready(id) then return false,"NotReady" end
  for i=#waiting,1,-1 do if not ready(waiting[i]) then table.remove(waiting,i) end end
  table.insert(waiting,id);if #waiting<2 then return true,"Queued" end
  local a,b=waiting[1],waiting[2];starting=true
  local ok,result=pcall(startPair,a,b);starting=false;table.clear(waiting)
  if not ok or not result then return false,"StartFailed" end
  active={a,b};return true,"Started"
 end
 function api.Remove(id: number): boolean api.Cancel(id);return table.find(active,id)~=nil end
 function api.Finish(): () table.clear(waiting);table.clear(active);starting=false end
 function api.Snapshot(): {waiting: {number},active: {number},starting: boolean} return {waiting=table.clone(waiting),active=table.clone(active),starting=starting} end
 return table.freeze(api)
end
return table.freeze(Queue)
