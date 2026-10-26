--!strict

local JourneyCheck = {}
local COUNTS = {[3]=24,[5]=18,[6]=12,[7]=16,[9]=18}

local function key(p: BasePart): string
	return string.format("%d:%d:%d",p:GetAttribute("SectionIndex"),p:GetAttribute("SectionStep"),p:GetAttribute("Lane"))
end

local function edge(surface: BasePart, direction: Vector3, anchor: Vector3): number
	local radius = surface.Size.Magnitude+5
	local origin = Vector3.new(anchor.X,surface.Position.Y+surface.Size.Y/2-.08,anchor.Z) + direction*radius
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {surface}
	local hit = workspace:Raycast(origin,-direction*radius*2,params)
	assert(hit,"Landing edge ray missed "..surface:GetFullName())
	return (hit.Position-anchor):Dot(direction)
end

local function topHit(surface: BasePart, xz: Vector3, hintY: number): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {surface}
	local originY = math.max(hintY + 64, surface.Position.Y + surface.Size.Y/2 + 64)
	local bottomY = math.min(hintY - 64, surface.Position.Y - surface.Size.Y/2 - 64)
	return workspace:Raycast(Vector3.new(xz.X,originY,xz.Z),Vector3.new(0,bottomY-originY,0),params)
end

local function measuredAnchor(surface: BasePart, pad: BasePart, xz: Vector3): Vector3
	local hit = topHit(surface,xz,pad.Position.Y + pad.Size.Y/2)
	assert(hit,"Physical surface has no top at metadata pad: "..key(pad).." -> "..surface:GetFullName())
	return hit.Position
end

local function walkableTopHit(surface: BasePart, xz: Vector3, hintY: number): RaycastResult?
	local hit=topHit(surface,xz,hintY)
	if hit and hit.Normal.Y>=.7 then return hit end
	return nil
end

local function slopedEdge(surface: BasePart, direction: Vector3, anchor: Vector3, pad: BasePart): number
	local lastInside = 0
	local firstOutside: number? = nil
	local step = .5
	local radius = surface.Size.Magnitude + 6
	for distance=step,radius,step do
		if walkableTopHit(surface,anchor + direction*distance,pad.Position.Y + pad.Size.Y/2) then
			lastInside = distance
		else
			firstOutside = distance
			break
		end
	end
	assert(firstOutside,"Continuous shoulder edge ray did not leave "..surface:GetFullName())
	local low,high = lastInside,firstOutside :: number
	for _=1,8 do
		local middle = (low+high)/2
		if walkableTopHit(surface,anchor + direction*middle,pad.Position.Y + pad.Size.Y/2) then
			low = middle
		else
			high = middle
		end
	end
	return low
end

local function intervalKey(link: BasePart): string
	local section = link:GetAttribute("SectionIndex")
	local fromStep = link:GetAttribute("FromStep")
	local toStep = link:GetAttribute("SectionStep")
	local lane = link:GetAttribute("Lane")
	assert(typeof(section)=="number" and typeof(fromStep)=="number" and typeof(toStep)=="number","RouteLink is missing its interval metadata: "..link:GetFullName())
	if typeof(lane)~="number" then lane=0 end
	return string.format("%d:%d:%d:%d",section,fromStep,toStep,lane)
end

local function launchAnchor(surface: BasePart, other: BasePart, checkpoints: Instance): Vector3
	if surface.Parent ~= checkpoints and not surface:GetAttribute("SharedCheckpoint") then return surface.Position end
	local relative = surface.CFrame:PointToObjectSpace(other.Position)
	local topWidth=surface.Size.X/(surface:GetAttribute("TopSpread") or 1)
	return (surface.CFrame*CFrame.new(math.clamp(relative.X,-topWidth/2+2,topWidth/2-2),0,0)).Position
end

function JourneyCheck.Run(model: Model, baseline: Model?): any
	assert(game:GetService("RunService"):IsStudio(),"Studio only")
	assert(model:IsDescendantOf(workspace),"The geometry check requires a workspace candidate")
	assert(model:GetAttribute("BuilderVersion")==8 and model:GetAttribute("JourneyRevision")==1,"Expected Journey revision")
	assert(model:GetAttribute("AltitudeRevision")==2 and model:GetAttribute("RiverFinishRevision")==1,"Accepted passes retained")
	assert(#model.Checkpoints:GetChildren()==19,"Checkpoint count changed")
	local pads: {[string]: BasePart} = {}
	local surfaces: {[string]: BasePart} = {}
	local central: {[number]: BasePart} = {}
	local motions: {[string]: number} = {}
	local meshCount,boxCount,hullCount,physicalChecks = 0,0,0,0
	for _,p in ipairs(model:GetDescendants()) do
		if not p:IsA("BasePart") then continue end
		if p:GetAttribute("RoutePad") then pads[key(p)]=p end
		if p:GetAttribute("RouteSurface") then surfaces[key(p)]=p end
		if p:GetAttribute("RouteIndex") then central[p:GetAttribute("RouteIndex") :: number]=p end
		local kind = p:GetAttribute("MotionKind")
		if kind then
			motions[kind]=(motions[kind] or 0)+1
			assert(p.Anchored and p:GetAttribute("MotionDuration")>0,"Invalid authored motion")
			if kind ~= "MovingLog" then
				assert(p.Parent:FindFirstChild("Warning"),"Missing motion warning")
				assert(p:GetAttribute("WarningDuration")>=1.4,"Warning was shortened")
			end
		end
		if p:IsA("MeshPart") then
			meshCount+=1
			if not p.CanCollide and not p.CanTouch and not p.CanQuery then
				assert(p.CollisionFidelity==Enum.CollisionFidelity.Box,"Noninteractive collision was not simplified")
				boxCount+=1
			elseif p:GetAttribute("RouteSurface") then
				assert(p.CollisionFidelity==Enum.CollisionFidelity.Hull,"Playable stone requires its convex outline")
				hullCount+=1
			elseif p:GetAttribute("RouteSupport") or p:GetAttribute("RouteLink") or p:GetAttribute("SharedRouteGround") or p:GetAttribute("ProjectileCover") or kind=="LavaSpurt" then
				assert(p.CollisionFidelity==Enum.CollisionFidelity.Hull,"Interactive geology requires its visible outline")
			end
		end
	end
	assert(motions.RollingBoulder==5 and motions.Snowball==8 and motions.Avalanche==8,"Expected modest hazard additions")
	assert(motions.MovingLog==100 and motions.RollingLog==6 and motions.LavaSpurt==12,"Unrelated hazard counts changed")
	assert(#central==170,"Central route node count changed")
	local checkpointParams=RaycastParams.new()
	checkpointParams.FilterType=Enum.RaycastFilterType.Include
	checkpointParams.FilterDescendantsInstances={model}
	checkpointParams.RespectCanCollide=true
	for _,pad in ipairs(model.Checkpoints:GetChildren()) do
		local hit=workspace:Raycast(pad.Position+Vector3.new(0,20,0),Vector3.new(0,-40,0),checkpointParams)
		assert(hit and hit.Position.Y<=pad.Position.Y+pad.Size.Y/2+.1,"Physical scenery covers a checkpoint trigger: "..pad.Name)
	end
	local sharedGround,links={},{}
	local lavaWedges=0
	for _,p in ipairs(model:GetDescendants()) do
		if not p:IsA("BasePart") then continue end
		if p:GetAttribute("SharedRouteGround") then table.insert(sharedGround,p) end
		if p:GetAttribute("RouteLink") then table.insert(links,p) end
		if p.Name=="LavaBasin" then assert(not p.CanTouch and p:GetAttribute("HazardType")==nil,"Retired lava area still kills outside the visible channel") end
		if p.Name=="ConnectedLavaChannel" then
			assert(p.CanTouch and p:GetAttribute("HazardType")=="Kill" and p.Transparency==0,"Visible lava lacks its hazard")
			lavaWedges+=1
		end
	end
	assert(lavaWedges==68,"Lava channel is incomplete")
	local snowRays,linkRays=0,0
	local groundParams=RaycastParams.new()
	groundParams.FilterType=Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances=sharedGround
	for _,pad in pairs(pads) do
		local section=pad:GetAttribute("SectionIndex")
		if section~=8 and section~=10 then continue end
		for _,x in ipairs({0,-.3,.3}) do
			local origin=(pad.CFrame*CFrame.new(pad.Size.X*x,pad.Size.Y/2+3,0)).Position
			assert(workspace:Raycast(origin,Vector3.new(0,-5,0),groundParams),"Snow path lacks visible physical ground: "..key(pad))
			snowRays+=1
		end
	end
	for _,link in ipairs(links) do
		local section,step=link:GetAttribute("SectionIndex"),link:GetAttribute("SectionStep")
		local a,b=pads[string.format("%d:%d:0",section,link:GetAttribute("FromStep") or step-1)],pads[string.format("%d:%d:0",section,step)]
		assert(a and b,"Rock shoulder lacks route endpoints")
		for sample=0,10 do
			local t=sample/10
			local top=(a.Position+Vector3.new(0,a.Size.Y/2,0)):Lerp(b.Position+Vector3.new(0,b.Size.Y/2,0),t)
			assert(topHit(link,top,top.Y+2.4),"Connected shoulder has a physical gap")
			linkRays+=1
		end
	end
	local function linkCoversPad(link: BasePart, pad: BasePart): boolean
		local section,step=pad:GetAttribute("SectionIndex"),pad:GetAttribute("SectionStep")
		local fromStep,toStep=link:GetAttribute("FromStep"),link:GetAttribute("SectionStep")
		local lane=link:GetAttribute("Lane")
		return link:GetAttribute("SectionIndex")==section and (typeof(lane)~="number" or lane==0)
			and typeof(step)=="number" and typeof(fromStep)=="number" and typeof(toStep)=="number" and step>=fromStep and step<=toStep
	end
	local function resolvedLink(pad: BasePart, other: BasePart?): {surface: BasePart, interval: string, anchor: Vector3}
		assert(pad:GetAttribute("ContinuousRoute") and pad:GetAttribute("Lane")==0,"Expected a main-lane continuous route pad: "..key(pad))
		local candidates: {BasePart} = {}
		for _,link in ipairs(links) do if linkCoversPad(link,pad) then table.insert(candidates,link) end end
		assert(#candidates>0,"Continuous route pad has no RouteLink interval: "..key(pad))
		local preferred: {BasePart} = {}
		if other and other:GetAttribute("SectionIndex")==pad:GetAttribute("SectionIndex") and other:GetAttribute("Lane")==0 then
			local step,otherStep=pad:GetAttribute("SectionStep"),other:GetAttribute("SectionStep")
			if typeof(step)=="number" and typeof(otherStep)=="number" then
				for _,link in ipairs(candidates) do
					local fromStep,toStep=link:GetAttribute("FromStep"),link:GetAttribute("SectionStep")
					if (otherStep>step and typeof(toStep)=="number" and toStep>step)
						or (otherStep<step and typeof(fromStep)=="number" and fromStep<step) then
						table.insert(preferred,link)
					end
				end
			end
		end
		if #preferred==0 then preferred=candidates end
		local bestLink: BasePart? = nil
		local bestHit: RaycastResult? = nil
		for _,link in ipairs(preferred) do
			local hit=topHit(link,pad.Position,pad.Position.Y+pad.Size.Y/2)
			if hit and (not bestHit or hit.Position.Y>bestHit.Position.Y) then bestLink,bestHit=link,hit end
		end
		assert(bestLink and bestHit,"Continuous RouteLink has no physical top at its world XZ: "..key(pad))
		return {surface=bestLink,interval=intervalKey(bestLink),anchor=bestHit.Position}
	end
	local function sharedContinuousLink(a: BasePart, b: BasePart): BasePart?
		if not a:GetAttribute("ContinuousRoute") or not b:GetAttribute("ContinuousRoute") then return nil end
		for _,link in ipairs(links) do
			if linkCoversPad(link,a) and linkCoversPad(link,b)
				and topHit(link,a.Position,a.Position.Y+a.Size.Y/2)
				and topHit(link,b.Position,b.Position.Y+b.Size.Y/2) then
				return link
			end
		end
		return nil
	end
	local function adjacentRouteLinkTop(pad: BasePart, xz: Vector3): RaycastResult?
		local highest: RaycastResult? = nil
		for _,link in ipairs(links) do
			if linkCoversPad(link,pad) then
				local hit=topHit(link,xz,pad.Position.Y+pad.Size.Y/2+3)
				if hit and (not highest or hit.Position.Y>highest.Position.Y) then highest=hit end
			end
		end
		return highest
	end
	local sharedLandingOverlaps={}
	local curvedRouteRays=0
	for _,pad in pairs(pads) do
		if not pad:GetAttribute("ContinuousRoute") then continue end
		for _,x in ipairs({0,-2,2}) do
			local sample=(pad.CFrame*CFrame.new(x,0,0)).Position
			assert(adjacentRouteLinkTop(pad,sample),"Curved route leaves its physical shoulder: "..key(pad))
			curvedRouteRays+=1
		end
	end
	for id,surface in pairs(surfaces) do
		local pad=pads[id]
		assert(pad and not pad.CanCollide and surface.CanCollide,"Metadata pad and physical surface disagree")
		local top=pad.Position.Y+pad.Size.Y/2
		assert(math.abs(surface.Position.Y+surface.Size.Y/2-top)<.02,"Surface top moved")
		local firstHit=workspace:Raycast(Vector3.new(pad.Position.X,top+8,pad.Position.Z),Vector3.new(0,-10,0),checkpointParams)
		assert(firstHit,"Landing centre has no physical ground: "..id)
		if firstHit.Position.Y>top+.1 then
			local other=firstHit.Instance
			assert(other:GetAttribute("RoutePad") or other:GetAttribute("RouteSurface") or other:GetAttribute("SharedRouteGround"),"Scenery obstructs a landing centre: "..id)
			table.insert(sharedLandingOverlaps,{landing=id,sharedSurface=other.Name,rise=firstHit.Position.Y-top})
		end
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances={surface}
		for _,point in ipairs({Vector3.zero,Vector3.new(.3,0,.3),Vector3.new(-.3,0,-.3)}) do
			local center=(surface.CFrame*CFrame.new(point.X*pad.Size.X,0,point.Z*pad.Size.Z)).Position
			local hit=workspace:Raycast(Vector3.new(center.X,top+3,center.Z),Vector3.new(0,-5,0),params)
			assert(hit and math.abs(hit.Position.Y-top)<.05,"Physical landing does not match the visible top: "..id)
			physicalChecks+=1
		end
	end
	local jumps={}
	local continuousConnections=0
	local variance={}
	for section,count in pairs(COUNTS) do
		local minHeight,maxHeight,offsetCount=math.huge,-math.huge,0
		for _,lane in ipairs({-1,0,1}) do
			for step=1,count do
				local b=pads[string.format("%d:%d:%d",section,step,lane)] or pads[string.format("%d:%d:0",section,step)]
				local a: BasePart?=nil
				if step>1 then
					a=pads[string.format("%d:%d:%d",section,step-1,lane)] or pads[string.format("%d:%d:0",section,step-1)]
				else
					local first=pads[string.format("%d:1:0",section)]
					a=central[first:GetAttribute("RouteIndex")-1]
				end
				assert(a and b,"Missing route connection")
				local height=b:GetAttribute("HeightVariation")
				if typeof(height)=="number" then minHeight=math.min(minHeight,height);maxHeight=math.max(maxHeight,height);offsetCount+=1 end
				local sharedLink=sharedContinuousLink(a,b)
				if sharedLink then
					continuousConnections+=1
					continue
				end
				local fromLink=if a:GetAttribute("ContinuousRoute") then resolvedLink(a,b) else nil
				local toLink=if b:GetAttribute("ContinuousRoute") then resolvedLink(b,a) else nil
				local from=if fromLink then fromLink.surface else surfaces[key(a)] or a
				local to=if toLink then toLink.surface else surfaces[key(b)] or b
				local fromAnchor=if fromLink then fromLink.anchor else measuredAnchor(from,a,launchAnchor(from,to,model.Checkpoints))
				local toAnchor=if toLink then toLink.anchor else measuredAnchor(to,b,launchAnchor(to,from,model.Checkpoints))
				local delta=(toAnchor-fromAnchor)*Vector3.new(1,0,1)
				local direction=delta.Unit
				local exit=if fromLink then slopedEdge(from,direction,fromAnchor,a) else edge(from,direction,fromAnchor)
				local entrance=if toLink then slopedEdge(to,-direction,toAnchor,b) else edge(to,-direction,toAnchor)
				local gap=delta.Magnitude-exit-entrance
				local rise=toAnchor.Y-fromAnchor.Y
				table.insert(jumps,{section=section,lane=lane,step=step,gap=gap,rise=rise,
					source=a.Name,target=b.Name,sourceSurface=from.Name,targetSurface=to.Name,
					sourceKey=key(a),targetKey=key(b),takeoffEdge=exit,targetEdge=entrance,
					launchAnchor={x=fromAnchor.X,y=fromAnchor.Y,z=fromAnchor.Z},targetAnchor={x=toAnchor.X,y=toAnchor.Y,z=toAnchor.Z}})
			end
		end
		assert(offsetCount>0 and maxHeight-minHeight>1,"Uneven platform heights were lost")
		variance[tostring(section)]={minimum=minHeight,maximum=maxHeight,samples=offsetCount}
	end
	table.sort(jumps,function(a,b)return a.gap>b.gap end)
	local preservation={}
	if baseline then
		local oldPads={}
		for _,p in ipairs(baseline:GetDescendants()) do
			if p:IsA("BasePart") and p:GetAttribute("RoutePad") then oldPads[key(p)]=p end
		end
		for id,p in pairs(pads) do
			local section=p:GetAttribute("SectionIndex")
			if section==2 then
				local old=oldPads[id]
				assert(old and (p.Size-old.Size).Magnitude<.001 and (p.Position-old.Position).Magnitude<.001,"Protected route geometry changed: "..id)
				assert(p.CFrame.LookVector:Dot(old.CFrame.LookVector)>.999999,"Protected route orientation changed: "..id)
				preservation[tostring(section)]=(preservation[tostring(section)] or 0)+1
			end
		end
	end
	local length=0
	local previous=model.Start
	for _,p in ipairs(central) do length+=(p.Position-previous.Position).Magnitude;previous=p end
	assert(math.abs(model.CourseInfo:GetAttribute("RouteLengthStuds")-length)<=.51,"Route length metadata is stale")
	return {status="Passed",motions=motions,meshes=meshCount,box=boxCount,hull=hullCount,
		snowGroundRays=snowRays,connectedShoulderRays=linkRays,lavaWedges=lavaWedges,
		continuousConnections=continuousConnections,
		curvedRouteRays=curvedRouteRays,
		sharedLandingOverlaps=sharedLandingOverlaps,
		physicalLandingRays=physicalChecks,preservedPads=preservation,heightVariation=variance,routeLength=length,jumps=jumps}
end

return JourneyCheck
