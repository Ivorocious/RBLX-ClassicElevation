return function(Loader)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Edit mode only")
	local checks, failures = {},{}
	local function check(name,value)
		table.insert(if value then checks else failures,name)
	end
	local function inside(item,parent)
		local p,s=item.AbsolutePosition-parent.AbsolutePosition,item.AbsoluteSize
		return p.X>=-1 and p.Y>=-1 and p.X+s.X<=parent.AbsoluteSize.X+1 and p.Y+s.Y<=parent.AbsoluteSize.Y+1
	end
	local gui=Instance.new("ScreenGui")
	gui.Name,gui.IgnoreGuiInset,gui.Parent="SoftLandingEditChecks",true,game.CoreGui
	local ok,err=pcall(function()
		for _,size in {Vector2.new(1360,779),Vector2.new(375,700),Vector2.new(667,320),Vector2.new(800,600),Vector2.new(844,390)} do
			local host=Instance.new("Frame")
			host.Size,host.Position,host.Parent=UDim2.fromOffset(size.X,size.Y),UDim2.fromOffset(-10000,-10000),gui
			local modules=Loader.Load()
			modules.Lobby.InitPreview(host)
			for _,larger in {false,true} do
				if larger then modules.Lobby.ToggleLargeText() end
				for _,course in {"City Run V3","Shipwreck Cove","Classic Point-to-Point","Classic Elevation"} do
					modules.Lobby.Update("WaitingForPlayers","Lobby",nil,course,"PointToPoint")
					task.wait(.1)
					local root=host.LobbyUI.SafeArea
					local race,quest=root.RaceStack.NextRace,root.RaceStack.QuestTicket
					local tag=tostring(size).."/"..course.."/"..tostring(larger)
					check("contained "..tag,inside(root.Menu,root) and inside(root.Currencies,root) and inside(root.Phase,root) and inside(race,root) and inside(quest,root))
					local a,b=root.Phase,race
					check("phase clears race card "..tag,a.AbsolutePosition.X+a.AbsoluteSize.X+4<=b.AbsolutePosition.X or a.AbsolutePosition.Y+a.AbsoluteSize.Y+4<=b.AbsolutePosition.Y or b.AbsolutePosition.X+b.AbsoluteSize.X+4<=a.AbsolutePosition.X)
					check("course fits "..tag,race.Course.TextFits and race.Course.AbsolutePosition.Y+race.Course.AbsoluteSize.Y+1<=race.StatusPlate.AbsolutePosition.Y)
					check("race text fits "..tag,race.StatusPlate.Status.TextFits and race.RaceOptions.Title.TextFits and root.Phase.Capsule.Timer.TextFits)
					check("quiet idle "..tag,not root.Phase.Capsule.ProgressTrack.Visible and root.Phase.Capsule.Timer.Text=="Explore")
					check("status has no shadow "..tag,race:FindFirstChild("StatusPlateShadow")==nil and race.StatusPlate.BackgroundTransparency==1)
					check("empty quest honest "..tag,not quest.Progress.Visible and not quest.Node1.Visible and not quest.ProgressTrack.Visible and not quest.ViewAll.Visible and quest.Objective.Text=="No quests yet" and quest.Objective.TextFits)
					check("touch targets "..tag,race.RaceOptions.AbsoluteSize.Y>=43.9)
					for _,name in {"Shop","MyRacer","Records","Settings"} do check("nav fits "..tag..name,root.Menu[name].Label.TextFits and inside(root.Menu[name].Label,root.Menu[name])) end
				end
			end
			modules.Lobby.ToggleLargeText()
			modules.Lobby.SetReferencePreview()
			task.wait(.1)
			local root=host.LobbyUI.SafeArea
			check("approved fixture "..tostring(size),root.Currencies.Gold.Balance.Text=="0" and root.Currencies.Keys.Balance.Text=="—" and root.Phase.Capsule.Timer.Text=="00:18" and root.RaceStack.QuestTicket.Objective.Text=="No quests yet" and inside(root.RaceStack.QuestTicket,root))
			check("phase progress "..tostring(size),root.Phase.Capsule.ProgressTrack.Visible and root.Phase.Capsule.ProgressTrack.Remaining.Size.X.Scale==.75)
			host:Destroy();modules.Destroy()
		end
	end)
	gui:Destroy()
	assert(ok,err)
	return {passed=#checks,checks=checks,failed=#failures,failures=failures}
end
