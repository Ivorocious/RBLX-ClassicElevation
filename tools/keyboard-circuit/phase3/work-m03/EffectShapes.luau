local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local root = roblox.deserializeModel(fs.readFile('docs/artifacts/keyboard-circuit/phase3/KC_P3_M02_01_Native.rbxm'))[1]
local prefix = 'tools/keyboard-circuit/phase3/work-m03/sources/'
local sources = root.SourceSnapshot
for _, name in {'ArchiveEffectParts', 'ArchiveEffects'} do
 local item = roblox.Instance.new('ModuleScript'); item.Name, item.Source, item.Parent = name, fs.readFile(prefix..name..'.luau'), sources
end
local cache = {}
local function loadModule(item)
 if cache[item] then return cache[item] end
 local env = {script = item, require = loadModule, game = {GetService = function() return {} end}}
 for k,v in roblox do env[k] = v end
 cache[item] = luau.load(item.Source, {environment = env, debugName = item.Name})()
 return cache[item]
end
local anchors = loadModule(sources.ArchiveEffectParts).Build(root, root:GetAttribute('Origin'), nil)
local fx = loadModule(sources.ArchiveEffects)
local report = {parts = 0, waveBounds = 0, sampleCount = 0, families = {}, native = 'docs/artifacts/keyboard-circuit/phase3/KC_P3_M02_01_Native.rbxm', sourceHashes = {ArchiveEffectParts = serde.hash('sha256', fs.readFile(prefix..'ArchiveEffectParts.luau')), ArchiveEffects = serde.hash('sha256', fs.readFile(prefix..'ArchiveEffects.luau'))}}
for _, part in anchors:GetDescendants() do
 if part:IsA('BasePart') then
  report.parts += 1
  assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery and not part.CastShadow and part.Transparency == 1)
 end
 if part:GetAttribute('ArchiveEffectKind') ~= 'WaveBar' then continue end
 local family, index = part:GetAttribute('ArchiveEffectFamily'), part:GetAttribute('BarIndex')
 local limit = part:GetAttribute('MaxEffectSize').Y
 for step = 0, 1500 do
  local amount = fx.SampleWave(family, step / 1000, index, 1)
  assert(amount == amount and amount >= 0 and amount <= 1.2)
  amount = math.floor(amount * 60 + .5) / 60
  local height = .8 + amount * (if family == 'Thocky' then 4.2 else 3.1)
  assert(height <= limit + .00001)
  report.sampleCount += 1
 end
 assert(fx.SampleWave(family, -1, index, 1) == 0 and fx.SampleWave(family, 2, index, 1) == 0)
 report.waveBounds += 1
end
for _, family in {'Creamy','Thocky','Clacky','Clicky'} do
 local strips, traces = anchors:GetAttribute('Underlight'..family..'Count'), anchors:GetAttribute('Trace'..family..'Count')
 assert(strips > 0 and strips <= 16 and traces > 0 and traces <= 4)
 report.families[family] = {strips = strips, traces = traces}
end
assert(anchors:GetAttribute('UnderlightCount') <= 64 and anchors:GetAttribute('TracePathCount') <= 16)
for index = 1,4 do
 assert(fx.SampleContact({state='cancelled'}, index, 100, -math.huge) == 0)
 assert(fx.SampleContact({state='cancelled'}, index, 100, 100) == 0)
 assert(fx.SampleContact({state='stopped'}, index, 100, 100) == 0)
 assert(fx.SampleContact({state='ready'}, index, 100, -math.huge) == .74)
 assert(fx.SampleContact({state='loading',loaded=8,total=8}, index, 100, -math.huge) == .56)
 assert(fx.SampleContact({state='ready'}, index, 100+.0001+(index-1)*.1, 100) >= .99)
end
report.passed = true
fs.writeFile('tools/keyboard-circuit/phase3/work-m03/EffectShapesResult01.json', serde.encode('json', report, true))
print(serde.encode('json', report))


