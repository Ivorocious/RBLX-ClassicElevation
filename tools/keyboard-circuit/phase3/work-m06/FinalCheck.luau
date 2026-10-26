local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local work = "tools/keyboard-circuit/phase3/work-m06/"
local env = {Vector3=roblox.Vector3,CFrame=roblox.CFrame,Instance=roblox.Instance,Enum=roblox.Enum}
local fix = luau.load(fs.readFile(work .. "ExpertCheckpoints.luau"),{environment=env,injectGlobals=true})()
local rebuilt = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase3/M06-before-checkpoint-fix.rbxm"))[1]
fix.Apply(rebuilt)
local bytes=fs.readFile("docs/artifacts/keyboard-circuit/phase3/KC_P3_M06_01_Native.rbxm")
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
local aliasOrientationDifferences=0
for index,row in left do
	if row~=right[index] then
		local a,b=serde.decode("json",row),serde.decode("json",right[index])
		if a[1]==b[1] and a[1]:find("/AlternateTriggers/",1,true) and a[3]~=b[3] then
			local x,y=string.split(a[3],","),string.split(b[3],",")
			local samePosition=x[1]==y[1] and x[2]==y[2] and x[3]==y[3]
			local close=samePosition
			for component=4,12 do if math.abs(tonumber(x[component])-tonumber(y[component]))>.00101 then close=false end end
			if close then a[3]=b[3];aliasOrientationDifferences+=1 end
		end
		if serde.encode("json",a)==serde.encode("json",b) then continue end
		for field,value in a do if value~=b[field] then print(serde.encode("json",{path=a[1],field=field,expected=value,actual=b[field]})) end end
		error("Native fresh-source mismatch at "..index)
	end
end
local parts,keys,kills,sources=0,0,0,0
for _,v in reopened:GetDescendants() do
	if v:IsA("BasePart") then parts+=1;if v:GetAttribute("Pressable") then keys+=1 end;if v:GetAttribute("HazardType")=="Kill" then kills+=1;assert(v.Material==roblox.Enum.Material.Neon) end end
	if v:IsA("LuaSourceContainer") then sources+=1 end
	if v:IsA("TextLabel") then assert(v.Text~="/ 7" and v.Text~="7 CHECKPOINTS" and v.Text~="LAP FINISH","Stale checkpoint sign") end
end
local compiled=0
for _,directory in {work} do for _,name in fs.readDir(directory) do if name:sub(-5)==".luau" then luau.load(fs.readFile(directory..name),{debugName=name});compiled+=1 end end end

local result={passed=true,comparedRows=#left,parts=parts,pressTargets=keys,kills=kills,sources=sources,compiled=compiled,aliasOrientationDifferences=aliasOrientationDifferences,nativeBytes=#bytes,nativeSha256=serde.hash("sha256",bytes),origin=tostring(reopened:GetAttribute("Origin")),limits="Disk re-opening and fresh Expert checkpoint repair from the exact current pre-fix native copy. Original rows and new-marker positions use .001 precision; new-marker orientation components permit .001 serialization normalization. Native runtime checks are recorded separately."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase3/P3-M06-final-check-01.json",serde.encode("json",result,true))
print(serde.encode("json",result))
