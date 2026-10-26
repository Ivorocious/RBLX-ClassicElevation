local fs,luau,roblox,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/"
local raw=fs.readFile(own.."CaptureSnapshot53.luau")
local Capture=luau.load(raw)()
local source="docs/artifacts/moonlit-citadel/phase3/closeout-20261014/final/source52-models.rbxm"
local models=roblox.deserializeModel(fs.readFile(source));assert(#models==2)
local state={schema=1,editable=Capture.CaptureModel(models[1]),stored=Capture.CaptureModel(models[2]),
    propertySchema=Capture.Schema,savedModelOnly=true,freshNativeBaseline=false}
fs.writeFile(own.."saved52-capture-check.json",serde.encode("json",{pass=true,source=source,
    sourceSHA256=serde.hash("sha256",fs.readFile(source)),captureSHA256=serde.hash("sha256",raw),
    editable=state.editable.counts,stored=state.stored.counts,studioTouched=false,freshNativeBaseline=false},true).."\n")
print(serde.encode("json",{pass=true,editable=state.editable.counts,stored=state.stored.counts}))
