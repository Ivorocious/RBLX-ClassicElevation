local fs,roblox,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/"
local source="docs/artifacts/moonlit-citadel/phase3/closeout-20261014/final/source52-models.rbxm"
local models=roblox.deserializeModel(fs.readFile(source))
local classes={Folder=true,Model=true,MeshPart=true,StringValue=true,Lighting=true,Camera=true,
    Atmosphere=true,Sky=true,BloomEffect=true,BlurEffect=true,ColorCorrectionEffect=true,DepthOfFieldEffect=true,SunRaysEffect=true}
for _,model in models do classes[model.ClassName]=true;for _,item in model:GetDescendants() do classes[item.ClassName]=true end end
local db=roblox.getReflectionDatabase()
local ignored={Attributes=true,AttributesSerialize=true,Tags=true,UniqueId=true,HistoryId=true,DataCost=true,
    ReceiveAge=true,AssemblyLinearVelocity=true,AssemblyAngularVelocity=true,Velocity=true,RotVelocity=true,
    CurrentDistance=true,CurrentAngle=true,CurrentPosition=true,CurrentSpeed=true,TimePosition=true,
    PlaybackLoudness=true,IsLoaded=true,IsPlaying=true,IsPaused=true,Playing=true,MoveDirection=true,
    LocalTransparencyModifier=true}
local classProperties={}
for className in classes do
    local names,seen={},{};local current=className
    while current do
        local class=db:GetClass(current);assert(class,"Missing local reflection class "..current)
        for name,property in class.Properties do
            if not seen[name] and not ignored[name] then seen[name]=true;table.insert(names,name) end
        end
        current=class.Superclass
    end
    table.sort(names);classProperties[className]=names
end
local result={classProperties=classProperties,excludedDerivedOrIdentityProperties=ignored,
    sourceSavedModel=source,sourceSHA256=serde.hash("sha256",fs.readFile(source)),
    boundary="All reflected properties attempted; unavailable properties are recorded. Attributes and tags are captured separately. Derived motion/readings and engine-generated identities are excluded explicitly."}
fs.writeFile(own.."property-schema.json",serde.encode("json",result,true).."\n")
local classCount,propertyCount=0,0;for _,names in classProperties do classCount+=1;propertyCount+=#names end
print(serde.encode("json",{classes=classCount,properties=propertyCount,source=source}))
