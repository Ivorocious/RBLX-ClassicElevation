--!strict

local RunService=game:GetService("RunService")
local Wayfinding={}
type FormattedStatus={title: string,mode: string,seconds: number,words: string}

function Wayfinding.SetStatus(hazard: Instance,words: string,color: Color3?)
	local board=hazard:FindFirstChild("StatusBoard")
	if board and board:GetAttribute("DisplayedStatus")~=words then
		board:SetAttribute("DisplayedStatus",words)
		for _,v in board:GetDescendants() do if v:IsA("TextLabel") then v.Text=words end end
	end
	if board and board:IsA("BasePart") and color then board.Color=color end
end

function Wayfinding.CaptureStatus(hazard: Instance)
	local saved={parts={},labels={},board=hazard:FindFirstChild("StatusBoard"),formattedStatus=nil :: FormattedStatus?}
	if saved.board then saved.status=saved.board:GetAttribute("DisplayedStatus") end
	for _,part in hazard:GetChildren() do
		if part:IsA("BasePart") and (part.Name=="StatusBoard" or part:GetAttribute("TimedWarningStripe")==true) then
			table.insert(saved.parts,{part=part,color=part.Color})
			for _,label in part:GetDescendants() do
				if label:IsA("TextLabel") then table.insert(saved.labels,{label=label,text=label.Text}) end
			end
		end
	end
	return saved
end

function Wayfinding.RestoreStatus(saved)
	for _,record in saved.parts do record.part.Color=record.color end
	for _,record in saved.labels do record.label.Text=record.text end
	if saved.board then saved.board:SetAttribute("DisplayedStatus",saved.status) end
	saved.formattedStatus=nil
end

function Wayfinding.UpdateHazard(hazard: Instance,title: string,phase: string,alpha: number,timing,minimumEntry: number,state: {formattedStatus: FormattedStatus?}?): boolean
	local remaining=if phase=="Clear" then timing.Clear*(1-alpha) else 0
	local entryOpen=phase=="Clear" and remaining>=minimumEntry
	local color=if entryOpen then Color3.fromRGB(129,205,75) elseif phase=="Active" then Color3.fromRGB(245,110,82) else Color3.fromRGB(255,204,74)
	local waitSeconds=if phase=="Clear" then remaining+timing.Warning+timing.Active elseif phase=="Warning" then timing.Warning*(1-alpha)+timing.Active else timing.Active*(1-alpha)
	local mode=if entryOpen then "GO" elseif phase=="Active" then "STOP" else "WAIT"
	local seconds=math.ceil(if entryOpen then remaining-minimumEntry else waitSeconds)
	local cached=state and state.formattedStatus
	local words: string
	if cached and cached.title==title and cached.mode==mode and cached.seconds==seconds then
		words=cached.words
	else
		words=if entryOpen then string.format("%s: GO\nENTER NOW  %ds\nKeep moving",title,seconds)
			else string.format("%s: %s\nOPENS IN %ds\nStay behind line",title,mode,seconds)
		if state then state.formattedStatus={title=title,mode=mode,seconds=seconds,words=words} end
	end
	Wayfinding.SetStatus(hazard,words,color)
	local lamp=hazard:FindFirstChild("WarningLamp")
	if lamp and lamp:IsA("BasePart") then lamp.Color=color end
	for _,stripe in hazard:GetChildren() do
		if stripe:IsA("BasePart") and stripe:GetAttribute("TimedWarningStripe")==true then
			stripe.Color=if phase=="Warning" and math.floor(alpha*6)%2==0 then Color3.fromRGB(255,239,201) else color
		end
	end
	return entryOpen
end

-- PhaseAlpha and ClearRemaining change every frame and only Studio QA probes read them, so live servers skip them.
function Wayfinding.PublishPhase(hazard: Instance,phase: string,alpha: number,clearRemaining: number,entryOpen: boolean)
	if hazard:GetAttribute("Phase")~=phase then hazard:SetAttribute("Phase",phase) end
	if hazard:GetAttribute("EntryOpen")~=entryOpen then hazard:SetAttribute("EntryOpen",entryOpen) end
	if RunService:IsStudio() then
		hazard:SetAttribute("PhaseAlpha",alpha)
		hazard:SetAttribute("ClearRemaining",clearRemaining)
	end
end

return Wayfinding
