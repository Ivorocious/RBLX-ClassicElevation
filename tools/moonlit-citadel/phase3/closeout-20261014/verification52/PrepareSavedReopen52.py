from pathlib import Path

own = Path(__file__).resolve().parent
original = own.parent / "CheckFinal51Recovery.luau"
text = original.read_text(encoding="utf8")
start = text.index("local expected=")
end = text.index("local report=", start)
text = text[:start] + '''local bindings=serde.decode("json",fs.readFile("tools/moonlit-citadel/phase3/closeout-20261014/verification52/bindings52.json"))
assert(bindings.ready,"Bind final Source52 inputs first")
local expected=bindings.expected
''' + text[end:]
text = text.replace("source51", "source52").replace("Source51", "Source52")
text = text.replace("95352d0a83b16c50acb3c6e6e6c99a4d1deffb19cac81105783b1bea9e240f03", "3b0e592a6695e70a881d30daaa7bfb27915a60bec6acce75e685358b7a7266c2")
text = text.replace('artifacts.."before/closeout_plan51.json"', 'artifacts.."combined-plan52.json"')
text = text.replace('read("source52-models.rbxm")', 'read("source52-models.rbxm")')
addition = '''
local luau=require("@lune/luau")
local own="tools/moonlit-citadel/phase3/closeout-20261014/verification52/"
local Geometry=luau.load(fs.readFile(own.."GeometryAudit52.luau"),{environment={CFrame=roblox.CFrame,Vector3=roblox.Vector3}})()
local Override=luau.load(fs.readFile(own.."PartAdjustmentOracle52.luau"),{environment={Vector3=roblox.Vector3}})()
local decodedPlan=serde.decode("json",planRaw)
assert(Override.ValidatePlan(decodedPlan.units).pass,"Saved geometry must bind the one exact approved depth adjustment")
local libraries={}
for _,library in roblox.deserializeModel(fs.readFile(artifacts.."../enclosure-repair-20261013/before/enclosure_before_source48_kits.rbxm")) do
 for key,name in Geometry.LibraryNames do if library.Name==name then libraries[key]=library end end
end
local er=roblox.deserializeModel(fs.readFile(artifacts.."../enclosure-repair-20261013/before/enclosure_er01_library_verified.rbxm"))[1]
libraries.ER01=er
local geometry=Geometry.Run(models,libraries,decodedPlan,{expectedIdentity={source=expected.source,build=expected.build,packet=expected.packet},
 expectedUnits=expected.units,expectedMeshes=expected.meshes,expectedCourses=2,requireSourceGuard=false,adjustmentOracle=Override,
 approvedTemplateMetadata=serde.decode("json",fs.readFile("tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json"))})
report.savedGeometryOracle=geometry
assert(geometry.geometryPass,"Saved material-part geometry differs from the explicit final plan")
report.fullProtectedNativeRecordsComparedHere=false
report.protectionBoundary="Saved contact/arrow counts and root pivots pass here; root's fresh native52 exact nonworld/Phase1/arrow comparison remains a separate required proof."
'''
text = text.replace('report.moduleExportRoots=', addition + '\nreport.moduleExportRoots=')
(own / "CheckSavedReopen52.luau").write_text(text, encoding="utf8", newline="")
print("Prepared saved52 count, source parity and explicit corrected geometry reopen harness")
