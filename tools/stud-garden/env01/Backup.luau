--!strict

local Backup = {}

local function difference(a: any, b: any): number
	local kind = typeof(a)
	if kind ~= typeof(b) then return math.huge end
	if kind == "number" then return math.abs(a-b) end
	if kind == "Vector3" then return math.max(math.abs(a.X-b.X),math.abs(a.Y-b.Y),math.abs(a.Z-b.Z)) end
	if kind == "Color3" then return math.max(math.abs(a.R-b.R),math.abs(a.G-b.G),math.abs(a.B-b.B)) end
	if kind == "CFrame" then
		local aa,bb,maximum = {a:GetComponents()},{b:GetComponents()},0
		for i=1,12 do maximum=math.max(maximum,math.abs(aa[i]-bb[i])) end
		return maximum
	end
	return if a==b then 0 else math.huge
end

function Backup.Compare(original: {Instance}, restored: {Instance}): any
	assert(#original==#restored,"Archive root count differs")
	local result: any = {verified=true,instances=0,parts=0,scripts=0,sourceBytes=0,maximumNumericDifference=0,tolerance=0.00001}
	local function compare(a: Instance,b: Instance,path: string)
		assert(a.Name==b.Name and a.ClassName==b.ClassName,"Archive hierarchy differs: "..path)
		result.instances+=1
		local fields={}
		if a:IsA("BasePart") then
			result.parts+=1
			fields={"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","TopSurface","BottomSurface","Reflectance","CastShadow"}
		end
		if a:IsA("Part") then table.insert(fields,"Shape") end
		if a:IsA("LuaSourceContainer") then
			result.scripts+=1
			result.sourceBytes+=#a.Source
			table.insert(fields,"Source")
		end
		if a:IsA("MeshPart") then table.insert(fields,"MeshId");table.insert(fields,"TextureID") end
		if a:IsA("TextLabel") then
			for _,key in {"Text","TextColor3","TextSize","BackgroundColor3","BackgroundTransparency","TextTransparency","TextStrokeTransparency","TextStrokeColor3","FontFace","TextScaled","TextWrapped"} do table.insert(fields,key) end
		end
		for _,key in ipairs(fields) do
			local d=difference((a :: any)[key],(b :: any)[key])
			result.maximumNumericDifference=math.max(result.maximumNumericDifference,d)
			assert(d<=result.tolerance,"Archive property differs: "..path.."/"..key)
		end
		if a:IsA("Model") then
			local d=difference(a:GetPivot(),(b :: Model):GetPivot())
			result.maximumNumericDifference=math.max(result.maximumNumericDifference,d)
			assert(d<=result.tolerance,"Archive model pivot differs: "..path)
			assert((a.PrimaryPart==nil)==((b :: Model).PrimaryPart==nil),"Archive primary part differs")
			if a.PrimaryPart then assert(a.PrimaryPart.Name==(b :: Model).PrimaryPart.Name,"Archive primary part name differs") end
		end
		local attrsA,attrsB=a:GetAttributes(),b:GetAttributes()
		for key,value in pairs(attrsA) do
			local d=difference(value,attrsB[key])
			result.maximumNumericDifference=math.max(result.maximumNumericDifference,d)
			assert(d<=result.tolerance,"Archive attribute differs: "..path.."/@"..key)
		end
		for key in pairs(attrsB) do assert(attrsA[key]~=nil,"Archive added attribute") end
		local childrenA,childrenB=a:GetChildren(),b:GetChildren()
		assert(#childrenA==#childrenB,"Archive child count differs: "..path)
		for index,child in ipairs(childrenA) do compare(child,childrenB[index],path.."/"..child.Name.."["..index.."]") end
	end
	for index,root in ipairs(original) do compare(root,restored[index],root.Name) end
	return result
end

function Backup.Run(roots: {Instance},filename: string): any
	assert(game.PlaceId==85558151074819 and game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Intended Edit place required")
	assert(filename:match("^[a-z0-9%-]+%.rbxm$"),"Invalid archive filename")
	local serializer,http=game:GetService("SerializationService"),game:GetService("HttpService")
	local originalHttp=http.HttpEnabled
	local restored
	local okay,result=xpcall(function()
		local body=buffer.tostring(serializer:SerializeInstancesAsync(roots))
		http.HttpEnabled=true
		local url="http://127.0.0.1:8773/"..filename
		local response=http:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=body})
		assert(response.Success,"Archive write failed: "..response.StatusCode)
		local readback=http:GetAsync(url,true)
		assert(readback==body,"Archive saved bytes differ")
		restored=serializer:DeserializeInstancesAsync(buffer.fromstring(readback))
		local comparison=Backup.Compare(roots,restored)
		comparison.receipt=http:JSONDecode(response.Body)
		return comparison
	end,debug.traceback)
	if restored then for _,object in ipairs(restored) do object:Destroy() end end
	http.HttpEnabled=originalHttp
	assert(okay,result)
	return result
end

return Backup

