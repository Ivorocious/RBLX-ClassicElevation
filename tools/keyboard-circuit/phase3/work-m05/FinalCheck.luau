local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local work = "tools/keyboard-circuit/phase3/work-m05/"
local packet = serde.decode("json",fs.readFile(work .. "InstallPacket.json"))
local env = {Vector3=roblox.Vector3,CFrame=roblox.CFrame,Instance=roblox.Instance,Enum=roblox.Enum}
local adapter = luau.load(packet.adapter,{environment=env,injectGlobals=true})()
local presentation = luau.load(packet.presentation,{environment=env,injectGlobals=true})()
local rebuilt = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase3/m05-recovery/M04-before-basic-handoff.rbxm"))[1]
adapter.Apply(rebuilt);presentation.Apply(rebuilt)
for _,v in rebuilt.SourceSnapshot:GetChildren() do if not packet.sources[v.Name] then v:Destroy() else v.Source=packet.sources[v.Name] end end
local runtime=roblox.Instance.new("Script");runtime.Name="CourseRuntime";runtime.Source=packet.runtime;runtime.Disabled=false;runtime.Parent=rebuilt
local bytes=fs.readFile("docs/artifacts/keyboard-circuit/phase3/KC_P3_M05_01_Native.rbxm")
local reopened=roblox.deserializeModel(bytes)[1]
local function number(value) return string.format("%.3f", if math.abs(value)<.0005 then 0 else value) end
local function pose(value) local out={};for _,x in {value:GetComponents()} do table.insert(out,number(x)) end;return table.concat(out,",") end
local function vector(value) return number(value.X)..","..number(value.Y)..","..number(value.Z) end
local function property(item, name, default)
	local ok, value = pcall(function() return item[name] end)
	return if ok then value else default
end
local function path(item, root)
	local names={}
	while item~=root do table.insert(names,1,item.Name);item=item.Parent end
	return table.concat(names,"/")
end
local function rows(root)
	local result={}
	local items=root:GetDescendants();table.insert(items,root)
	for _,v in items do
		local row={path(root==v and root or v,root),v.ClassName}
		if v:IsA("BasePart") then
			table.insert(row,pose(v.CFrame));table.insert(row,vector(v.Size));table.insert(row,tostring(v.Color));table.insert(row,v.Material.Name)
			for _,name in {"CanCollide","CanTouch","CanQuery","Anchored","CastShadow","Transparency"} do table.insert(row,tostring(v[name])) end
			if v:IsA("MeshPart") then table.insert(row,property(v,"MeshId",""));table.insert(row,property(v,"TextureID","")) end
		elseif v:IsA("LuaSourceContainer") then table.insert(row,serde.hash("sha256",v.Source))
		elseif v:IsA("TextLabel") then table.insert(row,v.Text)
		elseif v:IsA("SurfaceGui") then table.insert(row,v.Face.Name);table.insert(row,tostring(v.Enabled));table.insert(row,number(v.MaxDistance))
		elseif v:IsA("Vector3Value") then table.insert(row,vector(v.Value)) end
		local attrs={}
		for name,value in v:GetAttributes() do
			local kind=typeof(value)
			if kind=="CFrame" then value=pose(value) elseif kind=="Vector3" then value=vector(value) elseif kind=="number" then value=number(value) else value=tostring(value) end
			table.insert(attrs,name.."="..value)
		end
		table.sort(attrs);table.insert(row,table.concat(attrs,";"))
		table.insert(result,serde.encode("json",row))
	end
	table.sort(result);return result
end
local left,right=rows(rebuilt),rows(reopened)
assert(#left==#right,"Native re-open count mismatch")
for index,row in left do assert(row==right[index],"Native fresh-source mismatch at "..index.."\n"..row.."\n"..right[index]) end
local parts,keys,kills,sources=0,0,0,0
for _,v in reopened:GetDescendants() do
	if v:IsA("BasePart") then parts+=1;if v:GetAttribute("Pressable") then keys+=1 end;if v:GetAttribute("HazardType")=="Kill" then kills+=1;assert(v.Material==roblox.Enum.Material.Neon) end end
	if v:IsA("LuaSourceContainer") then sources+=1 end
	if v:IsA("TextLabel") then assert(v.Text~="/ 7" and v.Text~="7 CHECKPOINTS" and v.Text~="LAP FINISH","Stale checkpoint sign") end
end
local compiled=0
for _,directory in {work,work.."sources/"} do for _,name in fs.readDir(directory) do if name:sub(-5)==".luau" then luau.load(fs.readFile(directory..name),{debugName=name});compiled+=1 end end end
for _,source in packet.globals do luau.load(source);compiled+=1 end
local result={passed=true,comparedRows=#left,parts=parts,pressTargets=keys,kills=kills,sources=sources,compiled=compiled,nativeBytes=#bytes,nativeSha256=serde.hash("sha256",bytes),origin=tostring(reopened:GetAttribute("Origin")),limits="Disk re-opening and fresh adapter/presentation/runtime rebuild from the owner's exact pre-handoff native copy; physical poses use .001 precision. Native runtime checks are recorded separately."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase3/P3-M05-final-check-01.json",serde.encode("json",result,true))
print(serde.encode("json",result))
