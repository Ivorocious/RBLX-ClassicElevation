local function install(port, packetHash)
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and not RunService:IsRunning() and game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177)
	local H,E=game:GetService("HttpService"),game:GetService("EncodingService")
	local beforeHttp=H.HttpEnabled
	local function hash(raw)
		local b,h=E:ComputeBufferHash(buffer.fromstring(raw),Enum.HashAlgorithm.Sha256),{}
		for i=0,buffer.len(b)-1 do h[#h+1]=string.format("%02x",buffer.readu8(b,i)) end
		return table.concat(h)
	end
	local function at(path)
		local item=game
		for name in path:gmatch("[^/]+") do item=item and item:FindFirstChild(name) end
		return item
	end
	local report={candidate="MC_P2_C01_R06",packetHash=packetHash,sources={},temporary=true}
	local ok,reason=xpcall(function()
		assert(#game.ServerStorage.CourseLibrary:GetChildren()==7 and game.ServerStorage.CourseLibrary.Course_MoonlitCitadel:GetAttribute("CandidateId")==report.candidate)
		assert(not game.ServerStorage:FindFirstChild("MoonlitPhase2Tools") and not game.ReplicatedStorage:FindFirstChild("MoonlitPhase2Tools"),"Preserve existing tools")
		H.HttpEnabled=true
		local response=H:RequestAsync({Url="http://127.0.0.1:"..port.."/MC_P2_R06_original_tools01.json",Method="GET"})
		assert(response.Success and hash(response.Body)==packetHash,"Diagnostic packet binding failed")
		local packet=H:JSONDecode(response.Body)
		assert(packet.candidate==report.candidate and packet.placeId==game.PlaceId and packet.gameId==game.GameId and packet.creatorId==game.CreatorId and #packet.sources==9)
		for _,row in packet.sources do
			assert(not at(row.instancePath) and hash(row.source)==row.sha256 and #row.source<200000,"Preserve existing sources "..row.instancePath)
		end
		for _,parent in {game.ServerStorage,game.ReplicatedStorage} do
			local folder=Instance.new("Folder");folder.Name="MoonlitPhase2Tools";folder:SetAttribute("OwnedMoonlitTest",true);folder.Parent=parent
		end
		for _,row in packet.sources do
			local parent,name=row.instancePath:match("^(.*)/([^/]+)$")
			local item=Instance.new(row.class);item.Name=name;item.Source=row.source;item:SetAttribute("OwnedMoonlitTest",true)
			if item:IsA("BaseScript") then item.Disabled=true end
			item.Parent=assert(at(parent))
			assert(hash(item.Source:gsub("\r\n","\n"))==row.sha256,"Diagnostic source readback failed")
			report.sources[#report.sources+1]={path=row.instancePath,sha256=row.sha256}
		end
		for _,row in packet.sources do
			local item=at(row.instancePath)
			if item:IsA("BaseScript") then item.Disabled=false end
		end
	end,debug.traceback)
	H.HttpEnabled=beforeHttp
	report.ok,report.failure,report.httpRestored=ok,if ok then nil else tostring(reason),H.HttpEnabled==beforeHttp
	return H:JSONEncode(report)
end
return install
