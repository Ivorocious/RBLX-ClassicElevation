local fs,roblox,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/"
local base="docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/"
local function collect(path)
    local result={};local function add(item)
        if item:IsA("LuaSourceContainer") then assert(not result[item.Name]);result[item.Name]={class=item.ClassName,sha256=serde.hash("sha256",item.Source:gsub("\r\n","\n"))} end
    end
    for _,root in roblox.deserializeModel(fs.readFile(path)) do add(root);for _,item in root:GetDescendants() do add(item) end end
    return result
end
local old,new=collect(base.."before/source52-modules.rbxm"),collect(base.."final/source53-modules.rbxm")
local added,removed,changed={},{},{}
local a,b=0,0
for name,item in old do a+=1;if not new[name] then table.insert(removed,name) elseif new[name].sha256~=item.sha256 then table.insert(changed,name) end end
for name in new do b+=1;if not old[name] then table.insert(added,name) end end
table.sort(added);table.sort(removed);table.sort(changed)
local report={before=a,after=b,added=added,removed=removed,changed=changed,old=old,new=new}
fs.writeFile(own.."saved-source-inventory53.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",{before=a,after=b,added=added,removed=removed,changed=changed}))
