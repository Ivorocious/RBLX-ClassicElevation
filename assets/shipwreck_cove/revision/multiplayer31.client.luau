local map=workspace:WaitForChild("__SC31MultiplayerProbe",15);assert(map)
local cap=map:WaitForChild("Obstacles"):WaitForChild("WalkingSurfaces"):WaitForChild("Spar00")
local events={};local last="";local start=os.clock();local frames={}
local connection=game:GetService("RunService").RenderStepped:Connect(function(dt)table.insert(frames,dt)end)
script:SetAttribute("Ready",true)
repeat
 local state=tostring(cap.CanCollide)..":"..tostring(cap.CanQuery)..":"..tostring(map:GetAttribute("ProbePhase"))
 if state~=last then last=state;table.insert(events,{time=workspace:GetServerTimeNow(),state=state,position={cap.Position.X,cap.Position.Y,cap.Position.Z}})end
 task.wait(.03)
until map:GetAttribute("ProbePhase")=="Complete" or os.clock()-start>120
connection:Disconnect();table.sort(frames)
script:SetAttribute("Result",game.HttpService:JSONEncode({player=game.Players.LocalPlayer.Name,events=events,frames=#frames,medianFrameSeconds=frames[math.max(1,math.floor(#frames*.5))],p95FrameSeconds=frames[math.max(1,math.floor(#frames*.95))],limited="Local desktop Studio test; current client view; not target-mobile or 20-racer performance."}))
