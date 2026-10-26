local function update(port, packetHash)
	local RunService=game:GetService("RunService")
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
	local report={candidate="MC_P2_C01_R06",packetHash=packetHash,sources={},temporary=true,arrivalExcluded=true}
	local ok,reason=xpcall(function()
		assert(game.ServerStorage.CourseLibrary.Course_MoonlitCitadel:GetAttribute("CandidateId")==report.candidate)
		H.HttpEnabled=true
		local response=H:RequestAsync({Url="http://127.0.0.1:"..port.."/MC_P2_R06_original_tools02.json",Method="GET"})
		assert(response.Success and hash(response.Body)==packetHash,"Diagnostic packet binding failed")
		local packet=H:JSONDecode(response.Body)
		assert(packet.candidate==report.candidate and packet.placeId==game.PlaceId and packet.gameId==game.GameId and packet.creatorId==game.CreatorId and #packet.sources==11)
		for _,row in packet.sources do
			assert(hash(row.source)==row.sha256 and #row.source<200000)
			local item=at(row.instancePath)
			if row.previousSha256 then
				assert(item and item.ClassName==row.class and item:GetAttribute("OwnedMoonlitTest")==true and hash(item.Source:gsub("\r\n","\n"))==row.previousSha256,"Preserve existing source "..row.instancePath)
			else assert(not item,"Preserve existing instance "..row.instancePath) end
		end
		local parent=game.ServerStorage.MoonlitR06OriginalRecovery
		assert(not parent:FindFirstChild("DiagnosticTools01BeforeScope"))
		local archive=Instance.new("Folder");archive.Name="DiagnosticTools01BeforeScope";archive.Parent=parent
		for _,row in packet.sources do
			local item=at(row.instancePath)
			if item then
				local saved=item:Clone();saved:SetAttribute("OriginalDiagnosticPath",row.instancePath)
				if saved:IsA("BaseScript") then saved.Disabled=true end
				saved.Parent=archive
				if item.Source:gsub("\r\n","\n")~=row.source then item.Source=row.source end
			else
				local parentPath,name=row.instancePath:match("^(.*)/([^/]+)$")
				item=Instance.new(row.class);item.Name=name;item.Source=row.source;item:SetAttribute("OwnedMoonlitTest",true)
				if item:IsA("BaseScript") then item.Disabled=true end
				item.Parent=assert(at(parentPath))
			end
			assert(hash(item.Source:gsub("\r\n","\n"))==row.sha256)
			report.sources[#report.sources+1]={path=row.instancePath,sha256=row.sha256}
		end
		for _,row in packet.sources do local item=at(row.instancePath);if item:IsA("BaseScript") then item.Disabled=false end end
	end,debug.traceback)
	H.HttpEnabled=beforeHttp
	report.ok,report.failure,report.httpRestored=ok,if ok then nil else tostring(reason),H.HttpEnabled==beforeHttp
	return H:JSONEncode(report)
end
return update
